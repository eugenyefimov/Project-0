provider "aws" {
  region = var.primary_region
  alias  = "primary"

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  region = var.secondary_region
  alias  = "secondary"

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Terraform state management using S3 and DynamoDB
terraform {
  backend "s3" {}
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Primary Region Resources
module "vpc_primary" {
  source = "./modules/vpc"
  providers = {
    aws = aws.primary
  }
  
  region_name          = var.primary_region
  vpc_cidr             = var.primary_vpc_cidr
  public_subnet_cidrs  = var.primary_public_subnets
  private_subnet_cidrs = var.primary_private_subnets
  environment          = var.environment
}

module "alb_primary" {
  source = "./modules/alb"
  providers = {
    aws = aws.primary
  }
  
  vpc_id             = module.vpc_primary.vpc_id
  public_subnet_ids  = module.vpc_primary.public_subnet_ids
  environment        = var.environment
  region_name        = var.primary_region
}

module "ec2_primary" {
  source = "./modules/ec2"
  providers = {
    aws = aws.primary
  }
  
  vpc_id             = module.vpc_primary.vpc_id
  private_subnet_ids = module.vpc_primary.private_subnet_ids
  alb_sg_id          = module.alb_primary.alb_sg_id
  environment        = var.environment
  region_name        = var.primary_region
  target_group_arn   = module.alb_primary.target_group_arn
  app_bucket         = module.s3_cloudfront.s3_bucket_name
  app_hash           = filemd5(data.archive_file.app_zip.output_path)
}

# Secondary Region Resources
module "vpc_secondary" {
  source = "./modules/vpc"
  providers = {
    aws = aws.secondary
  }
  
  region_name          = var.secondary_region
  vpc_cidr             = var.secondary_vpc_cidr
  public_subnet_cidrs  = var.secondary_public_subnets
  private_subnet_cidrs = var.secondary_private_subnets
  environment          = var.environment
}

module "alb_secondary" {
  source = "./modules/alb"
  providers = {
    aws = aws.secondary
  }
  
  vpc_id             = module.vpc_secondary.vpc_id
  public_subnet_ids  = module.vpc_secondary.public_subnet_ids
  environment        = var.environment
  region_name        = var.secondary_region
}

module "ec2_secondary" {
  source = "./modules/ec2"
  providers = {
    aws = aws.secondary
  }
  
  vpc_id             = module.vpc_secondary.vpc_id
  private_subnet_ids = module.vpc_secondary.private_subnet_ids
  alb_sg_id          = module.alb_secondary.alb_sg_id
  environment        = var.environment
  region_name        = var.secondary_region
  target_group_arn   = module.alb_secondary.target_group_arn
  app_bucket         = module.s3_cloudfront.s3_bucket_name
  app_hash           = filemd5(data.archive_file.app_zip.output_path)
}

# Global Resources
module "route53" {
  source = "./modules/route53"
  
  domain_name        = var.domain_name
  primary_alb_dns    = module.alb_primary.alb_dns_name
  secondary_alb_dns      = module.alb_secondary.alb_dns_name
  primary_alb_zone_id   = module.alb_primary.alb_zone_id
  secondary_alb_zone_id = module.alb_secondary.alb_zone_id
  primary_region     = var.primary_region
  secondary_region   = var.secondary_region
}

module "dynamodb" {
  source = "./modules/dynamodb"
  
  table_names        = ["products", "carts", "orders"]
  primary_region     = var.primary_region
  secondary_region   = var.secondary_region
}

module "s3_cloudfront" {
  source = "./modules/s3"
  
  bucket_name        = var.s3_bucket_name
  environment        = var.environment
}

data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../app"
  output_path = "${path.module}/app.zip"
}

resource "aws_s3_object" "app_zip" {
  bucket = module.s3_cloudfront.s3_bucket_name
  key    = "app.zip"
  source = data.archive_file.app_zip.output_path
  etag   = filemd5(data.archive_file.app_zip.output_path)
}

# Security Resources
module "security" {
  source = "./modules/security"
  
  providers = {
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
  }
}

# Backup Resources
module "backup" {
  source = "./modules/backup"
  
  environment        = var.environment
  dynamodb_table_arns = [
    for t in ["products", "carts", "orders"] :
    "arn:aws:dynamodb:*:*:table/${t}"
  ]
}

# Cost Management Resources
module "cost" {
  source = "./modules/cost"
  
  providers = {
    aws = aws.primary
  }
  
  budget_limit = "1000"
  admin_email  = "admin@example.com"
}

# Monitoring Resources
module "monitoring" {
  source = "./modules/monitoring"
  
  providers = {
    aws = aws.primary
  }
  
  primary_region   = var.primary_region
  secondary_region = var.secondary_region
}