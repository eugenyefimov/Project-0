variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "1000"
}

variable "admin_email" {
  description = "Email address for budget notifications"
  type        = string
  default     = "admin@example.com"
}