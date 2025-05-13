# FineFinds Infrastructure Overview

## Introduction
This document provides a comprehensive overview of the FineFinds e-commerce platform infrastructure built with AWS CDK in TypeScript. It serves as the main reference for DevOps team members to understand our cloud architecture, deployment patterns, and environment configurations.

## Architecture Overview

### Infrastructure as Code
- **Framework**: AWS CDK (Cloud Development Kit) with TypeScript
- **Repository**: `finefinds-devops-cicd`
- **Deployment Tool**: AWS CloudFormation (managed by CDK)

### Core Infrastructure Components

#### Compute
- **ECS/Fargate**: Containerized application services
- **Auto-scaling**: Based on CPU/memory utilization
- **Auto-shutdown**: Implemented for non-production environments

#### Storage
- **S3 Buckets**: Media, uploads, backups, and logs
- **RDS**: PostgreSQL database (Aurora in production)
- **ElastiCache**: Redis for caching

#### Networking
- **VPC**: Isolated network environment
- **Load Balancers**: Application Load Balancers (ALB)
- **CloudFront**: CDN for content delivery

#### Security
- **Cognito**: User authentication and authorization
- **WAF**: Web Application Firewall (production only)
- **KMS**: Key Management Service for encryption
- **IAM**: Role-based access control

#### Monitoring
- **CloudWatch**: Metrics, logs, and alarms
- **SNS**: Notifications for alarms

## Environment Configurations

We maintain multiple environments to support our development lifecycle:

### Production Environment
Production hosts the live application used by customers.

### Development Environment
Development environment for ongoing feature development.

### Other Environments
- **QA**: For quality assurance testing
- **Sandbox**: For experimental features and testing

## Environment-Specific Details

Each environment has its own configuration file in `infra/env/` that defines environment-specific settings.

## Next Steps
- See [Environment Configurations](environment-configurations.md) for detailed settings per environment
- See [Infrastructure Costs](infrastructure-costs.md) for cost analysis
- See [DevOps Procedures](devops-procedures.md) for common operational tasks 