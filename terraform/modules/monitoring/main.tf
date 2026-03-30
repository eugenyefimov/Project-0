resource "aws_cloudwatch_dashboard" "cross_region" {
  provider       = aws.primary
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
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.primary_alb_arn_suffix, { "region": var.primary_region }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.secondary_alb_arn_suffix, { "region": var.secondary_region }]
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