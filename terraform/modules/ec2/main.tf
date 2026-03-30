resource "aws_security_group" "ec2" {
  name        = "${var.environment}-ec2-sg-${var.region_name}"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${var.environment}-ec2-sg-${var.region_name}"
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-launch-template-${var.region_name}"
  description   = "App Hash: ${var.app_hash}"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  
  vpc_security_group_ids = [aws_security_group.ec2.id]
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y unzip python3 python3-pip amazon-cloudwatch-agent
    
    mkdir -p /opt/ecommerce
    cd /opt/ecommerce
    
    # Download the zipped application artifact from S3
    aws s3 cp s3://${var.app_bucket}/app.zip .
    unzip app.zip
    
    # Install dependencies
    pip3 install -r requirements.txt
    pip3 install gunicorn
    
    # Configure Systemd Service
    cat << 'SERVICE' > /etc/systemd/system/ecommerce.service
    [Unit]
    Description=E-Commerce App
    After=network.target

    [Service]
    User=root
    WorkingDirectory=/opt/ecommerce
    Environment="PORT=80"
    Environment="AWS_DEFAULT_REGION=${var.region_name}"
    ExecStart=/usr/local/bin/gunicorn -b 0.0.0.0:80 app:app
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Configure CloudWatch Agent for Gunicorn logs
    cat << 'CWAG' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "${var.environment}-ecommerce-app-logs",
                "log_stream_name": "{instance_id}",
                "retention_in_days": 14
              }
            ]
          }
        }
      }
    }
    CWAG

    # Start CloudWatch Agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

    # Start and enable the service
    systemctl daemon-reload
    systemctl start ecommerce
    systemctl enable ecommerce
    EOF
  )
  
  tag_specifications {
    resource_type = "instance"
    
    tags = {
      Name        = "${var.environment}-app-instance-${var.region_name}"
      AppHash     = var.app_hash
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-asg-${var.region_name}"
  vpc_zone_identifier = var.private_subnet_ids
  desired_capacity    = 2
  min_size            = 2
  max_size            = 10
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  target_group_arns = [var.target_group_arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }
  
  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-${var.region_name}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.environment}-scale-up-${var.region_name}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.environment}-scale-down-${var.region_name}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-high-cpu-${var.region_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
  
  alarm_description = "Scale up if CPU utilization is above 80% for 4 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.environment}-low-cpu-${var.region_name}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
  
  alarm_description = "Scale down if CPU utilization is below 20% for 4 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role-${var.region_name}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.environment}-ec2-role-${var.region_name}"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "s3_read_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile-${var.region_name}"
  role = aws_iam_role.ec2_role.name
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}