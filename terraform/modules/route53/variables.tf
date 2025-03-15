variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "primary_alb_dns" {
  description = "DNS name of the primary ALB"
  type        = string
}

variable "secondary_alb_dns" {
  description = "DNS name of the secondary ALB"
  type        = string
}

variable "primary_alb_zone_id" {
  description = "Zone ID of the primary ALB"
  type        = string
}

variable "secondary_alb_zone_id" {
  description = "Zone ID of the secondary ALB"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary AWS region"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}