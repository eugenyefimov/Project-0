variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Map of availability zones to public subnet cidrs"
  type        = map(string)
}

variable "private_subnet_cidrs" {
  description = "Map of availability zones to private subnet cidrs"
  type        = map(string)
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region_name" {
  description = "AWS region name"
  type        = string
}