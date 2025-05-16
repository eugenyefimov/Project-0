output "primary_detector_id" {
  description = "ID of the primary GuardDuty detector"
  value       = aws_guardduty_detector.primary.id
}

output "secondary_detector_id" {
  description = "ID of the secondary GuardDuty detector"
  value       = aws_guardduty_detector.secondary.id
}