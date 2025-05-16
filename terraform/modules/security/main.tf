resource "aws_guardduty_detector" "primary" {
  provider = aws.primary
  enable   = true
}

resource "aws_guardduty_detector" "secondary" {
  provider = aws.secondary
  enable   = true
}

resource "aws_config_configuration_recorder" "primary" {
  provider = aws.primary
  name     = "primary-config-recorder"
  
  recording_group {
    all_supported = true
  }
  
  role_arn = aws_iam_role.config_role.arn
}

resource "aws_iam_role" "config_role" {
  provider = aws.primary
  name     = "aws-config-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  provider   = aws.primary
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}