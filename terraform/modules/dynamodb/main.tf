resource "aws_dynamodb_table" "global_table" {
  name             = var.table_name
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "PK"
  range_key        = "SK"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  attribute {
    name = "PK"
    type = "S"
  }
  
  attribute {
    name = "SK"
    type = "S"
  }
  
  replica {
    region_name = var.secondary_region
  }
}

resource "aws_appautoscaling_target" "table_read" {
  provider           = aws.primary
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "table/${aws_dynamodb_table.global_table.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
  depends_on         = [aws_dynamodb_table.global_table]
}

resource "aws_appautoscaling_target" "table_write" {
  provider           = aws.primary
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "table/${aws_dynamodb_table.global_table.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
  depends_on         = [aws_dynamodb_table.global_table]
}

resource "aws_appautoscaling_policy" "table_read_policy" {
  provider           = aws.primary
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.table_read.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.table_read.resource_id
  scalable_dimension = aws_appautoscaling_target.table_read.scalable_dimension
  service_namespace  = aws_appautoscaling_target.table_read.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "table_write_policy" {
  provider           = aws.primary
  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.table_write.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.table_write.resource_id
  scalable_dimension = aws_appautoscaling_target.table_write.scalable_dimension
  service_namespace  = aws_appautoscaling_target.table_write.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = 70.0
  }
}