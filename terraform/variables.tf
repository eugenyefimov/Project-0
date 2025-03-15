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

variable "primary_azs" {
  description = "Availability Zones in primary region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "secondary_azs" {
  description = "Availability Zones in secondary region"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
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