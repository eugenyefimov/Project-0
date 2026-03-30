# Multi-Region AWS Web Architecture & Immutable OIDC Deployment Pipeline

A production-ready AWS deployment for a Python web application, built using Terraform with a focus on immutable infrastructure. It provisions a highly available network across multiple regions, securely federates GitHub Actions using OIDC, and integrates a Flask application closely with EC2 autoscaling and DynamoDB global tables.

## Key Engineering Decisions

- **Architected** a multi-region AWS infrastructure using Terraform, deploying an Application Load Balancer and Auto Scaling Groups across isolated VPC subnets, increasing fault tolerance and availability.
- **Engineered** an immutable rolling deployment strategy by linking S3 application artifact hashes to EC2 Launch Templates, enabling zero-downtime updates through ASG Instance Refreshes.
- **Secured** CI/CD deployment pipelines using GitHub OIDC federation and IAM least privilege policies, successfully eliminating all long-lived AWS security credentials.
- **Eliminated** SSH attack vectors by stripping Port 22 access, relying exclusively on AWS Systems Manager (SSM) for secure, audited instance administration.
- **Refactored** Infrastructure as Code (IaC) modularity by establishing global Provider `default_tags` and strictly implementing `.tfvars` environment separation across DRY modules.

## Architecture Overview

The infrastructure relies on immutable EC2 deployments integrated directly into the CI/CD pipeline. Application code is zipped by Terraform, pushed to S3, and ingested by EC2 Auto Scaling Groups leveraging Session Manager (SSM) instead of SSH for security. DynamoDB global tables replicate data redundantly across `us-east-1` and `us-west-2`.

                                     ┌─────────────┐
                                     │    Users    │
                                     └──────┬──────┘
                                            │
                                 ┌──────────┴──────────┐
                                 │                     │
                           ┌─────▼─────┐         ┌─────▼─────┐
                           │ CloudFront│         │  Route53  │
                           │    CDN    │         │DNSFailover│
                           └─────┬─────┘         └─────┬─────┘
                                 │                     │
     ┌─────────────────────────────────────────┐       │       ┌────────────────────────────────────────┐
     │ Primary Region (us-east-1)              │       │       │ Secondary Region (us-west-2)           │
     │                                         │       │       │                                        │
     │  ┌─────────────┐         ┌─────────────┐│       │       │┌─────────────┐         ┌─────────────┐ │
     │  │     S3      │         │  DynamoDB   ││       │       ││     S3      │         │  DynamoDB   │ │
     │  │   Bucket    │         │Global Tables││       │       ││   Bucket    │         │Global Tables│ │
     │  └──────┬──────┘         └──────┬──────┘│       │       │└──────┬──────┘         └──────┬──────┘ │
     │         │                       │       │       │       │       │                       │        │
     │  ┌──────▼──────────────────────────────┐│       │       │┌──────▼──────────────────────────────┐ │
     │  │ VPC                               │ ││       │       ││ VPC                               │ │ │
     │  │  ┌───────────────┐  ┌───────────┐ │ ││       │       ││  ┌───────────────┐  ┌───────────┐ │ │ │
     │  │  │ Public Subnet │  │   WAF     │ │ ││       │       ││  │ Public Subnet │  │   WAF     │ │ │ │
     │  │  │ ┌───────────┐ │  └─────┬─────┘ │ ││       │       ││  │ ┌───────────┐ │  └─────┬─────┘ │ │ │
     │  │  │ │    ALB    │◄┼────────┘       │ ││◄──────┼───────┼┼──┼►│    ALB    │◄┼────────┘       │ │ │
     │  │  │ └─────┬─────┘ │                │ ││       │       ││  │ └─────┬─────┘ │                │ │ │
     │  │  └───────┼───────┘                │ ││       │       ││  └───────┼───────┘                │ │ │
     │  │          │                        │ ││       │       ││          │                        │ │ │
     │  │  ┌───────┼───────┐                │ ││       │       ││  ┌───────┼───────┐                │ │ │
     │  │  │Private Subnet │                │ ││       │       ││  │Private Subnet │                │ │ │
     │  │  │ ┌───────────┐ │                │ ││       │       ││  │ ┌───────────┐ │                │ │ │
     │  │  │ │AutoScaling│ │                │ ││       │       ││  │ │AutoScaling│ │                │ │ │
     │  │  │ │  Group    │ │                │ ││       │       ││  │ │  Group    │ │                │ │ │
     │  │  │ │ ┌───────┐ │ │                │ ││       │       ││  │ │ ┌───────┐ │ │                │ │ │
     │  │  │ │ │EC2/SSM│ │ │                │ ││       │       ││  │ │ │EC2/SSM│ │ │                │ │ │
     │  │  │ │ └───────┘ │ │                │ ││       │       ││  │ │ └───────┘ │ │                │ │ │
     │  │  │ └───────────┘ │                │ ││       │       ││  │ └───────────┘ │                │ │ │
     │  │  └───────────────┘                │ ││       │       ││  └───────────────┘                │ │ │
     │  │                                   │ ││       │       ││                                   │ │ │
     │  └─────────────────────────────────────┘│       │       │└─────────────────────────────────────┘ │
     │                                         │       │       │                                        │
     │  ┌─────────────┐                        │       │       │  ┌─────────────┐                       │
     │  │ CloudWatch  │                        │       │       │  │ CloudWatch  │                       │
     │  │ & App Logs  │                        │       │       │  │ & App Logs  │                       │
     │  └─────────────┘                        │       │       │  └─────────────┘                       │
     └─────────────────────────────────────────┘       │       └────────────────────────────────────────┘
                                                       │
                                               ┌───────┴───────┐
                                               │ GitHub Actions│
                                               │ CI/CD Pipeline│
                                               └───────────────┘

The infrastructure includes:
- Multi-region EC2 instances running Gunicorn with immutable Instance Refreshes
- Secure shell access natively via AWS Systems Manager (SSM)
- Global Route53 DNS with health checks and failover routing
- Auto Scaling Groups for dynamic capacity management
- DynamoDB Global Tables for multi-region database replication
- Secure GitHub Actions CI/CD pipeline via AWS IAM OIDC Federation
- AWS CloudWatch Agent pushing application-level logs into centralized Log Groups

## CI/CD Pipeline

The GitHub Actions pipeline is authenticated exclusively via AWS Identity Providers (OIDC), ensuring 0 long-lived AWS credentials exist. It performs `tfsec` security scans, syntax validation, plans against active environments, and safely posts results to Pull Requests. Applying updates to the application code transparently cycles EC2 instances via ASG Instance Refresh.

## Deployment Guide

### Prerequisites
- AWS Account
- Terraform (v1.5.0 or later)
- GitHub account (for CI/CD)

### 1. Setup GitHub OIDC Federation

This project relies on OIDC. Do **not** use static `AWS_ACCESS_KEY_ID`.
Create an IAM Identity Provider for GitHub Actions and assign a Role with a Trust Policy constrained securely to this repository context:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:your-username/Project-0:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

Add the `AWS_ROLE_TO_ASSUME` secret to your GitHub Repository Settings.

### 2. Configure Environments

Backend configuration and Terraform variables are strictly isolated by environment. 

Review and edit the following files for your deployment:
- `terraform/backend/prod.conf`
- `terraform/environments/prod.tfvars`

### 3. Deploy via External CI/CD or Local

The GitHub Action triggers automatically when changes merge to `main`. 

**To plan and trace manually locally for testing:**
```bash
cd terraform

export AWS_PROFILE=your-profile

terraform init -backend-config=backend/prod.conf
terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

## Testing Failover

To test the failover capabilities:
1. Access the application using the Route53 domain name
2. Terminate the primary region instances through the Auto Scaling Group `Capacity` definitions.
3. Observe the automatic failover to the secondary region seamlessly.

## Cleanup

To destroy the infrastructure:

```bash
cd terraform
terraform destroy -var-file=environments/prod.tfvars
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.