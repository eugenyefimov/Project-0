provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

provider "aws" {
  region = var.secondary_region
  alias  = "secondary"
}

# Terraform state management using S3 and DynamoDB
terraform {
  backend "s3" {
    bucket         = "terraform-state-multi-region-project"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
  
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
  
  region_name        = var.primary_region
  vpc_cidr           = var.primary_vpc_cidr
  availability_zones = var.primary_azs
  environment        = var.environment
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
}

# Secondary Region Resources
module "vpc_secondary" {
  source = "./modules/vpc"
  providers = {
    aws = aws.secondary
  }
  
  region_name        = var.secondary_region
  vpc_cidr           = var.secondary_vpc_cidr
  availability_zones = var.secondary_azs
  environment        = var.environment
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
}

# Global Resources
module "route53" {
  source = "./modules/route53"
  
  domain_name        = var.domain_name
  primary_alb_dns    = module.alb_primary.alb_dns_name
  secondary_alb_dns  = module.alb_secondary.alb_dns_name
  primary_region     = var.primary_region
  secondary_region   = var.secondary_region
}

module "dynamodb" {
  source = "./modules/dynamodb"
  
  table_name         = var.dynamodb_table_name
  primary_region     = var.primary_region
  secondary_region   = var.secondary_region
}

module "s3_cloudfront" {
  source = "./modules/s3"
  
  bucket_name        = var.s3_bucket_name
  environment        = var.environment
}