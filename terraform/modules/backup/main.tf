resource "aws_backup_vault" "main" {
  name = "${var.environment}-backup-vault"
}

resource "aws_backup_plan" "main" {
  name = "${var.environment}-backup-plan"
  
  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)"
    
    lifecycle {
      delete_after = 30
    }
  }
}

resource "aws_backup_selection" "main" {
  name          = "${var.environment}-backup-selection"
  iam_role_arn  = aws_iam_role.backup_role.arn
  plan_id       = aws_backup_plan.main.id
  
  resources = [
    "arn:aws:dynamodb:*:*:table/${var.dynamodb_table_name}",
    "arn:aws:ec2:*:*:instance/*"
  ]
}


resource "aws_iam_role" "backup_role" {
  name = "${var.environment}-backup-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}