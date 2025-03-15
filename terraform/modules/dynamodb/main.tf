resource "aws_dynamodb_table" "primary" {
  provider         = aws.primary
  name             = var.table_name
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  replica {
    region_name = var.secondary_region
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  tags = {
    Name        = "${var.table_name}-${var.primary_region}"
    Environment = var.environment
  }
}

resource "aws_appautoscaling_target" "primary_read" {
  provider           = aws.primary
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "table/${var.table_name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_target" "primary_write" {
  provider           = aws.primary
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "table/${var.table_name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "primary_read_policy" {
  provider           = aws.primary
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.primary_read.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.primary_read.resource_id
  scalable_dimension = aws_appautoscaling_target.primary_read.scalable_dimension
  service_namespace  = aws_appautoscaling_target.primary_read.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "primary_write_policy" {
  provider           = aws.primary
  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.primary_write.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.primary_write.resource_id
  scalable_dimension = aws_appautoscaling_target.primary_write.scalable_dimension
  service_namespace  = aws_appautoscaling_target.primary_write.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = 70.0
  }
}