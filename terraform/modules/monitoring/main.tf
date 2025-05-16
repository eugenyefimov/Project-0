resource "aws_cloudwatch_dashboard" "cross_region" {
  provider       = aws.primary  # Add this line
  dashboard_name = "cross-region-monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", "app/primary-alb", { "region": var.primary_region }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", "app/secondary-alb", { "region": var.secondary_region }]
          ]
          view    = "timeSeries"
          stacked = false
          title   = "Healthy Hosts Across Regions"
          region  = var.primary_region
        }
      }
    ]
  })
}