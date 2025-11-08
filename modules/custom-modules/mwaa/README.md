# AWS Managed Workflows for Apache Airflow (MWAA) Module

This is a custom Terraform module for AWS Managed Workflows for Apache Airflow (MWAA). There is no official `terraform-aws-modules` module for MWAA, making this a perfect example of a custom module.

## Overview

AWS MWAA is a managed service for Apache Airflow that makes it easy to run Airflow workflows on AWS. This module creates:

- MWAA environment
- S3 bucket for DAGs and plugins
- IAM roles and policies for MWAA execution
- CloudWatch log groups for MWAA logs
- Network configuration (security groups and subnets)

## Usage

```hcl
module "mwaa" {
  source = "../../modules/custom-modules/mwaa"
  
  environment           = "dev"
  aws_region            = "ap-southeast-1"
  mwaa_environment_name = "dev-airflow"
  airflow_version       = "2.8.1"
  environment_class     = "mw1.small"
  
  security_group_ids = ["sg-xxxxxxxxx"]
  subnet_ids         = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
  
  max_workers = 10
  min_workers = 1
  
  common_tags = {
    Environment = "dev"
    CostCenter   = "development"
  }
}
```

## Requirements

- MWAA requires private subnets with NAT Gateway or VPC endpoints for internet access
- Security groups must allow outbound traffic
- S3 bucket must be in the same region as the MWAA environment

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name | string | - | yes |
| aws_region | AWS region | string | - | yes |
| mwaa_environment_name | Name of the MWAA environment | string | "" | no |
| airflow_version | Apache Airflow version | string | "2.8.1" | no |
| environment_class | Environment class | string | "mw1.small" | no |
| security_group_ids | Security group IDs | list(string) | - | yes |
| subnet_ids | Subnet IDs (must be private) | list(string) | - | yes |
| log_retention_days | CloudWatch log retention | number | 7 | no |
| log_level | Logging level | string | "INFO" | no |
| webserver_access_mode | Webserver access mode | string | "PRIVATE_ONLY" | no |
| max_workers | Maximum number of workers | number | 10 | no |
| min_workers | Minimum number of workers | number | 1 | no |
| weekly_maintenance_window_start | Maintenance window | string | "SUN:03:00" | no |
| common_tags | Common tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| mwaa_environment_arn | ARN of the MWAA environment |
| mwaa_environment_name | Name of the MWAA environment |
| mwaa_webserver_url | Webserver URL |
| mwaa_airflow_version | Apache Airflow version |
| s3_bucket_arn | ARN of the S3 bucket |
| s3_bucket_name | Name of the S3 bucket |
| execution_role_arn | ARN of the IAM execution role |
| cloudwatch_log_group_name | Name of the CloudWatch log group |

## Why This is a Custom Module

AWS MWAA is a relatively uncommon service that doesn't have an official `terraform-aws-modules` module. This makes it a perfect example of when you need to create a custom module with:

- Opinionated defaults for your organization
- Cross-service integration (S3, IAM, CloudWatch, VPC)
- Custom resource configuration logic


