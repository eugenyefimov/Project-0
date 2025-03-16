# Multi-Region AWS Infrastructure Deployment

This project demonstrates a highly available, fault-tolerant AWS infrastructure deployment across multiple regions using Infrastructure as Code (IaC) principles with Terraform.

## Architecture Overview


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
     │  └─────────────┘         └──────┬──────┘│       │       │└─────────────┘         └──────┬──────┘ │
     │                                 │       │       │       │                               │        │
     │  ┌─────────────────────────────────────┐│       │       │┌─────────────────────────────────────┐ │
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
     │  │  │ │ │  EC2  │ │ │                │ ││       │       ││  │ │ │  EC2  │ │ │                │ │ │
     │  │  │ │ └───────┘ │ │                │ ││       │       ││  │ │ └───────┘ │ │                │ │ │
     │  │  │ └───────────┘ │                │ ││       │       ││  │ └───────────┘ │                │ │ │
     │  │  └───────────────┘                │ ││       │       ││  └───────────────┘                │ │ │
     │  │                                   │ ││       │       ││                                   │ │ │
     │  └─────────────────────────────────────┘│       │       │└─────────────────────────────────────┘ │
     │                                         │       │       │                                        │
     │  ┌─────────────┐                        │       │       │  ┌─────────────┐                       │
     │  │ CloudWatch  │                        │       │       │  │ CloudWatch  │                       │
     │  │ Monitoring  │                        │       │       │  │ Monitoring  │                       │
     │  └─────────────┘                        │       │       │  └─────────────┘                       │
     └─────────────────────────────────────────┘       │       └────────────────────────────────────────┘
                                                       │
                                               ┌───────┴───────┐
                                               │ GitHub Actions│
                                               │ CI/CD Pipeline│
                                               └───────────────┘



The infrastructure includes:

- Multi-region EC2 instances behind Application Load Balancers
- Global Route53 DNS with health checks and failover routing
- Auto Scaling Groups for dynamic capacity management
- VPC with public and private subnets in each region
- S3 for static content and CloudFront for global content delivery
- DynamoDB Global Tables for multi-region database replication
- GitHub Actions for CI/CD pipeline
- AWS CloudWatch for monitoring and alerting
- AWS WAF for security

## Prerequisites

- AWS Account
- Terraform (v1.3.0 or later)
- AWS CLI configured with appropriate permissions
- GitHub account (for CI/CD)
- Python 3.8 or later (for the application)

## Project Structure
.
├── .github/
│   └── workflows/
│       ├── terraform.yml
│       └── project-setup.yml
├── app/
│   ├── routes/
│   ├── static/
│   ├── templates/
│   └── app.py
├── docs/
│   └── architecture.md
├── scripts/
│   ├── init-backend.bat
│   └── init-backend.sh
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── vpc/
│       ├── ec2/
│       ├── alb/
│       ├── route53/
│       ├── dynamodb/
│       └── s3/
├── .gitignore
├── requirements.txt
├── run.py
└── README.md


## Deployment

### Infrastructure Deployment

#### 1. Initialize the Terraform Backend

For Windows:
```
cd scripts init-backend.bat
```
For Unix/Linux:
 ```

cd scripts
chmod +x init-backend.sh
./init-backend.sh

```

#### 2. Deploy with Terraform

 ```

cd terraform
terraform init
terraform plan
terraform apply

```

### Application Deployment

#### 1. Set up Python Environment

```
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

```

#### 2. Configure Environment Variables

Create a `.env` file in the project root:

```

FLASK_ENV=development
SECRET_KEY=your-secret-key
AWS_REGION=us-east-1
PRODUCTS_TABLE=products
CARTS_TABLE=carts
ORDERS_TABLE=orders
S3_BUCKET=project0-static-assets

```

#### 3. Run the Application

 ```

python run.py

```

### CI/CD Deployment

The project includes a GitHub Actions workflow that automatically deploys changes when code is pushed to the main branch. To use this:

1. Fork the repository
2. Add the following secrets to your GitHub repository:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_ROLE_TO_ASSUME` (if using IAM roles)
   - `TERRAFORM_LOCK_TABLE` (DynamoDB table name for state locking)
3. Push changes to the main branch to trigger the deployment

## Testing Failover

To test the failover capabilities:

1. Access the application using the Route53 domain name
2. Shut down the primary region instances or ALB
3. Observe the automatic failover to the secondary region

## Cleanup

To destroy the infrastructure:


```

cd terraform
terraform destroy

```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
 