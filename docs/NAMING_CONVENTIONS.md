# Naming Conventions

This document defines the naming conventions enforced across all AWS resources in this repository.

## Overview

All resources follow a consistent naming pattern to ensure:
- **Consistency**: Same naming pattern across all resources
- **Traceability**: Easy to identify environment, region, and resource type
- **Compliance**: Meet AWS resource naming requirements
- **Automation**: Automatic name generation via `common.hcl`

## Naming Pattern

### Standard Format

```
{project}-{environment}-{region}-{resource-type}-{identifier}
```

### Components

| Component | Description | Example | Max Length |
|-----------|-------------|---------|------------|
| `project` | Project name | `terragrunt-layers` | 20 |
| `environment` | Environment (dev, staging, prod) | `dev` | 10 |
| `region` | AWS region (shortened) | `apse1` (from ap-southeast-1) | 10 |
| `resource-type` | Resource type | `vpc`, `eks`, `mwaa` | 20 |
| `identifier` | Optional identifier | `main`, `worker` | 20 |

### Examples

| Resource Type | Full Name | Short Name |
|--------------|-----------|------------|
| VPC | `terragrunt-layers-dev-apse1-vpc` | `dev-apse1-vpc` |
| EKS Cluster | `dev-apse1-eks-cluster` | `dev-apse1-eks` |
| S3 Bucket | `terragrunt-layers-dev-apse1-state` | `dev-apse1-state` |
| IAM Role | `terragrunt-dev-apse1-eks-role` | `dev-apse1-eks-role` |
| Security Group | `terragrunt-layers-dev-apse1-eks-sg` | `dev-apse1-eks-sg` |

## Resource-Specific Naming

### S3 Buckets

**Format**: `{project}-{env}-{region}-{resource-type}`

**Rules**:
- Must be globally unique
- Lowercase only
- No underscores
- 3-63 characters

**Example**: `terragrunt-layers-dev-apse1-state`

### DynamoDB Tables

**Format**: `{project}-{env}-{region}-{resource-type}`

**Rules**:
- Alphanumeric and hyphens only
- Max 255 characters

**Example**: `terragrunt-layers-dev-apse1-locks`

### KMS Keys

**Alias Format**: `alias/{project}/{env}/{region}/{resource-type}`

**Rules**:
- Forward slashes allowed
- Max 256 characters

**Example**: `alias/terragrunt-layers/dev/apse1/eks`

### IAM Roles

**Format**: `{project-short}-{env}-{region-short}-{resource-short}-role`

**Rules**:
- Max 64 characters
- Alphanumeric and `+=,.@-_` allowed

**Example**: `terragrunt-dev-apse1-eks-role`

### Security Groups

**Format**: `{project}-{env}-{region}-{resource-type}-sg`

**Rules**:
- Max 255 characters
- Alphanumeric and hyphens only

**Example**: `terragrunt-layers-dev-apse1-eks-sg`

### CloudWatch Log Groups

**Format**: `/aws/{project}/{env}/{region}/{resource-type}`

**Rules**:
- Forward slashes allowed
- Max 512 characters

**Example**: `/aws/terragrunt-layers/dev/apse1/eks`

### EKS Clusters

**Format**: `{env}-{region-short}-{resource-type}`

**Rules**:
- Max 100 characters
- Alphanumeric and hyphens only

**Example**: `dev-apse1-eks-cluster`

### VPCs

**Format**: `{project}-{env}-{region}-vpc`

**Example**: `terragrunt-layers-dev-apse1-vpc`

### Subnets

**Format**: `{project}-{env}-{region}-{type}-subnet-{az}`

**Example**: `terragrunt-layers-dev-apse1-public-subnet-1a`

## Region Shortening

To keep names within AWS limits, regions are shortened:

| Full Region | Shortened |
|-------------|-----------|
| `ap-southeast-1` | `apse1` |
| `us-east-1` | `useast1` |
| `us-west-2` | `uswest2` |
| `eu-west-1` | `euwest1` |

## Environment Codes

| Environment | Code |
|-------------|------|
| Development | `dev` |
| Staging | `staging` |
| Production | `prod` |

## Layer Codes

| Layer | Code |
|-------|------|
| Layer 0 - Foundation | `l0-foundation` |
| Layer 1 - Networking | `l1-networking` |
| Layer 2 - Workloads | `l2-workloads` |
| Layer 3 - Apps | `l3-apps` |

## Usage

### In Terragrunt Configurations

The naming conventions are automatically available via `common.hcl`:

```hcl
include "root" {
  path = find_in_parent_folders()
}

inputs = {
  # Use naming convention
  bucket_name = dependency.common.outputs.naming_convention.s3_bucket
  
  # Use common tags
  tags = dependency.common.outputs.common_tags
}
```

### In Terraform Modules

Access via variables:

```hcl
variable "naming_convention" {
  description = "Naming convention from common.hcl"
  type = object({
    resource_name = string
    s3_bucket     = string
    # ... other naming functions
  })
}

resource "aws_s3_bucket" "main" {
  bucket = var.naming_convention.s3_bucket
  tags   = var.common_tags
}
```

## Best Practices

1. **Always use `common.hcl`**: Don't hardcode names
2. **Follow the pattern**: Use the standard format for all resources
3. **Keep it short**: Use shortened region codes when needed
4. **Be consistent**: Same resource type = same naming pattern
5. **Document exceptions**: If a resource can't follow the pattern, document why

## AWS Resource Limits

| Resource Type | Max Length | Allowed Characters |
|--------------|------------|-------------------|
| S3 Bucket | 63 | lowercase, numbers, hyphens |
| DynamoDB Table | 255 | alphanumeric, hyphens |
| KMS Alias | 256 | alphanumeric, forward slashes |
| IAM Role | 64 | alphanumeric, `+=,.@-_` |
| Security Group | 255 | alphanumeric, hyphens |
| CloudWatch Log Group | 512 | alphanumeric, hyphens, forward slashes |
| EKS Cluster | 100 | alphanumeric, hyphens |
| VPC | 255 | alphanumeric, hyphens |

## Enforcement

Naming conventions are enforced via:
- `common.hcl` - Automatic name generation
- Terraform validation rules - Validate names in modules
- CI/CD checks - Pre-commit hooks to validate naming

## Examples

### Example 1: S3 Bucket for Terraform State

```hcl
# Automatically generated name
bucket_name = "terragrunt-layers-dev-apse1-state"
```

### Example 2: EKS Cluster

```hcl
# Automatically generated name
cluster_name = "dev-apse1-eks-cluster"
```

### Example 3: VPC

```hcl
# Automatically generated name
vpc_name = "terragrunt-layers-dev-apse1-vpc"
```

## Migration

If you have existing resources with different naming:
1. Document current naming
2. Plan migration to new convention
3. Update resources gradually
4. Update documentation

