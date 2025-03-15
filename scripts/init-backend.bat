@echo off
REM This script initializes the S3 backend for Terraform state management

REM Set variables
set BUCKET_NAME=terraform-state-multi-region-project
set DYNAMODB_TABLE=terraform-state-lock
set REGION=us-east-1

REM Create S3 bucket
aws s3api create-bucket --bucket %BUCKET_NAME% --region %REGION%

REM Enable versioning on the bucket
aws s3api put-bucket-versioning --bucket %BUCKET_NAME% --versioning-configuration Status=Enabled

REM Enable encryption on the bucket
aws s3api put-bucket-encryption --bucket %BUCKET_NAME% --server-side-encryption-configuration "{\"Rules\": [{\"ApplyServerSideEncryptionByDefault\": {\"SSEAlgorithm\": \"AES256\"}}]}"

REM Create DynamoDB table for state locking
aws dynamodb create-table --table-name %DYNAMODB_TABLE% --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region %REGION%

echo Terraform backend initialized successfully!