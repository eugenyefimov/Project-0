variable "bucket_name" {
  description = "Name of the S3 bucket for static content"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}