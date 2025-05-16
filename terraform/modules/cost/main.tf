resource "aws_budgets_budget" "monthly" {
  provider          = aws.primary  # Add this line
  name              = "monthly-budget"
  budget_type       = "COST"
  limit_amount      = "1000"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  
  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"
    
    subscriber_email_addresses = ["admin@example.com"]
  }
}