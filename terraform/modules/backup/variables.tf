variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs to backup"
  type        = list(string)
}