variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region_name" {
  description = "AWS region name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "example.com"
}