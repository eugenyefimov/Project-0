variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region_name" {
  description = "AWS region name"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the target group"
  type        = string
}