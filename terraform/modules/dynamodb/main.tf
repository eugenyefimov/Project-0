resource "aws_dynamodb_table" "global_table" {
  for_each         = toset(var.table_names)
  name           = each.value
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  replica {
    region_name = var.secondary_region
  }
  
  tags = {
    Name        = each.value
    Environment = var.environment
  }
}

resource "aws_appautoscaling_target" "primary_read" {
  for_each           = toset(var.table_names)
  provider           = aws.primary
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "table/${each.value}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
  depends_on         = [aws_dynamodb_table.global_table]
}

resource "aws_appautoscaling_target" "primary_write" {
  for_each           = toset(var.table_names)
  provider           = aws.primary
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "table/${each.value}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
  depends_on         = [aws_dynamodb_table.global_table]
}

resource "aws_appautoscaling_policy" "primary_read_policy" {
  for_each           = toset(var.table_names)
  provider           = aws.primary
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.primary_read[each.key].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.primary_read[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.primary_read[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.primary_read[each.key].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "primary_write_policy" {
  for_each           = toset(var.table_names)
  provider           = aws.primary
  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.primary_write[each.key].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.primary_write[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.primary_write[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.primary_write[each.key].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = 70.0
  }
}