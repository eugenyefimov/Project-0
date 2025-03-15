#!/bin/bash

# This script initializes the S3 backend for Terraform state management

# Set variables
BUCKET_NAME="terraform-state-multi-region-project"
DYNAMODB_TABLE="terraform-state-lock"
REGION="us-east-1"

# Create S3 bucket
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Enable encryption on the bucket
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION

echo "Terraform backend initialized successfully!"