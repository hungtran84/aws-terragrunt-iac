# Naming Conventions Guide

## Overview

This repository uses a **global naming convention** enforced via `common.hcl` to ensure consistency across all AWS resources.

## Quick Start

Naming conventions are automatically available in all Terragrunt configurations:

```hcl
include "root" {
  path = find_in_parent_folders()
}

inputs = {
  # Use naming convention
  bucket_name = var.naming_convention.s3_bucket
  
  # Use common tags
  tags = var.common_tags
}
```

## Naming Pattern

### Standard Format

```
{project}-{environment}-{region}-{resource-type}
```

### Example Names

| Resource Type | Generated Name |
|--------------|----------------|
| S3 Bucket | `terragrunt-layers-dev-apse1-state` |
| EKS Cluster | `dev-apse1-eks-cluster` |
| VPC | `terragrunt-layers-dev-apse1-vpc` |
| IAM Role | `terragrunt-dev-apse1-eks-role` |

## Available Naming Functions

Access via `var.naming_convention.*`:

- `s3_bucket` - S3 bucket name
- `dynamodb_table` - DynamoDB table name
- `kms_alias` - KMS key alias
- `iam_role` - IAM role name
- `security_group` - Security group name
- `cloudwatch_log_group` - CloudWatch log group name
- `eks_cluster` - EKS cluster name
- `vpc` - VPC name
- `resource_name` - Standard resource name
- `short_name` - Short resource name

## Common Tags

Common tags are automatically applied via `var.common_tags`:

```hcl
tags = var.common_tags
```

Tags include:
- `Project` - Project name
- `Environment` - Environment (dev, staging, prod)
- `Region` - AWS region
- `Layer` - Infrastructure layer
- `ManagedBy` - Always "Terraform"
- `Repository` - Repository name
- Environment-specific tags (CostCenter, Owner, etc.)

## See Also

For detailed naming conventions, see [NAMING_CONVENTIONS.md](NAMING_CONVENTIONS.md)

