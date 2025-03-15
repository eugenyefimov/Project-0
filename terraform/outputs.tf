output "primary_alb_dns" {
  description = "DNS name of the primary ALB"
  value       = module.alb_primary.alb_dns_name
}

output "secondary_alb_dns" {
  description = "DNS name of the secondary ALB"
  value       = module.alb_secondary.alb_dns_name
}

output "route53_nameservers" {
  description = "Nameservers for the Route53 zone"
  value       = module.route53.nameservers
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.s3_cloudfront.cloudfront_domain_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = var.dynamodb_table_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3_cloudfront.s3_bucket_name
}

output "primary_region" {
  description = "Primary AWS region"
  value       = var.primary_region
}

output "secondary_region" {
  description = "Secondary AWS region"
  value       = var.secondary_region
}