# FineFinds Infrastructure

This repository contains the Terraform configuration for the FineFinds infrastructure.

## Architecture

The infrastructure is organized into the following modules:

- **Network**: VPC, subnets, security groups, and other networking components
- **Storage**: S3 buckets for static assets, uploads, and backups
- **Database**: RDS instance and MongoDB Atlas cluster
- **Compute**: ECS cluster, services, and load balancer
- **Monitoring**: CloudWatch alarms, dashboards, and logging
- **Security**: IAM roles, KMS keys, and Cognito user pool

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform 1.0.0 or later
- Docker (for local development)

## Directory Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── _common/
│   │   ├── network/
│   │   ├── storage/
│   │   ├── database/
│   │   ├── compute/
│   │   ├── monitoring/
│   │   └── security/
│   └── environments/
│       ├── dev/
│       ├── qa/
│       ├── staging/
│       └── prod/
├── scripts/
│   ├── cleanup.sh
│   └── restore_secrets.sh
└── README.md
```

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/finefindslk-devops-cicd.git
   cd finefindslk-devops-cicd
   ```

2. Initialize Terraform:
   ```bash
   cd terraform/environments/dev
   terraform init
   ```

3. Create a `terraform.tfvars` file with your configuration:
   ```hcl
   project = "finefindslk"
   environment = "dev"
   aws_region = "us-east-1"
   
   # Add other required variables
   ```

4. Plan and apply the configuration:
   ```bash
   terraform plan
   terraform apply
   ```

## Environment Configuration

Each environment (dev, qa, staging, prod) has its own configuration in the `terraform/environments` directory. The configuration includes:

- Resource sizing based on environment needs
- VPC CIDR ranges and subnet configurations
- Security group rules
- Scaling parameters

## Security

- All sensitive data is stored in AWS Secrets Manager
- KMS encryption is used for data at rest
- IAM roles follow the principle of least privilege
- Security groups are configured to allow only necessary traffic

## Monitoring

- CloudWatch alarms for critical metrics
- Custom dashboards for each environment
- Log aggregation and analysis
- Performance monitoring

## Backup and Recovery

- Automated backups for RDS
- S3 versioning for uploaded files
- Cross-region replication for critical data
- Disaster recovery procedures documented

## Contributing

1. Create a feature branch
2. Make your changes
3. Run `terraform fmt` and `terraform validate`
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 