variable "primary_region" {
  description = "Primary AWS region for deployment"
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for deployment"
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment"
  default     = "production"
}

variable "primary_vpc_cidr" {
  description = "CIDR block for primary VPC"
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  description = "CIDR block for secondary VPC"
  default     = "10.1.0.0/16"
}

variable "primary_public_subnets" {
  description = "Map of AZs to public subnets in primary region"
  type        = map(string)
  default     = {
    "us-east-1a" = "10.0.0.0/24"
    "us-east-1b" = "10.0.1.0/24"
    "us-east-1c" = "10.0.2.0/24"
  }
}

variable "primary_private_subnets" {
  description = "Map of AZs to private subnets in primary region"
  type        = map(string)
  default     = {
    "us-east-1a" = "10.0.3.0/24"
    "us-east-1b" = "10.0.4.0/24"
    "us-east-1c" = "10.0.5.0/24"
  }
}

variable "secondary_public_subnets" {
  description = "Map of AZs to public subnets in secondary region"
  type        = map(string)
  default     = {
    "us-west-2a" = "10.1.0.0/24"
    "us-west-2b" = "10.1.1.0/24"
    "us-west-2c" = "10.1.2.0/24"
  }
}

variable "secondary_private_subnets" {
  description = "Map of AZs to private subnets in secondary region"
  type        = map(string)
  default     = {
    "us-west-2a" = "10.1.3.0/24"
    "us-west-2b" = "10.1.4.0/24"
    "us-west-2c" = "10.1.5.0/24"
  }
}

variable "domain_name" {
  description = "Domain name for the application"
  default     = "example.com"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  default     = "multi-region-app-data"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for static content"
  default     = "multi-region-static-content"
}