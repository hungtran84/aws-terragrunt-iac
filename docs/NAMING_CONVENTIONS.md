# Naming Conventions

This document defines the naming conventions enforced across all AWS resources in this repository.

## Overview

All resources follow a consistent naming pattern to ensure:
- **Consistency**: Same naming pattern across all resources
- **Traceability**: Easy to identify environment, region, and resource type
- **Compliance**: Meet AWS resource naming requirements
- **Automation**: Automatic name generation via `common-env.hcl`

## Quick Start

Naming conventions are automatically available in all Terragrunt configurations:

```hcl
include "root" {
  path = find_in_parent_folders()
}

locals {
  # Load global configuration
  global = read_terragrunt_config(find_in_parent_folders("common-env.hcl")).locals
  
  # Extract environment and region from path
  environment = local.path_parts[local.live_index + 1]
  region      = local.path_parts[local.live_index + 2]
  
  # Get region short code from global config
  region_short = try(local.global.region_short_map[local.region], "unknown")
  
  # Generate resource names
  bucket_name = "${local.global.project_name}-${local.environment}-${local.region_short}-state"
}
```

## Naming Pattern

### Standard Format

```
{project}-{environment}-{region}-{resource-type}-{identifier}
```

### Components

| Component | Description | Example | Max Length |
|-----------|-------------|---------|------------|
| `project` | Project name | `acme-platform` | 20 |
| `environment` | Environment (dev, staging, prod) | `dev` | 10 |
| `region` | AWS region (shortened) | `apse1` (from ap-southeast-1) | 10 |
| `resource-type` | Resource type | `vpc`, `eks`, `mwaa` | 20 |
| `identifier` | Optional identifier | `main`, `worker` | 20 |

### Example Names

| Resource Type | Full Name | Short Name |
|--------------|-----------|------------|
| S3 Bucket | `acme-platform-dev-apse1-state` | `dev-apse1-state` |
| DynamoDB Table | `acme-platform-dev-apse1-locks` | `dev-apse1-locks` |
| EKS Cluster | `dev-apse1-eks-cluster` | `dev-apse1-eks` |
| VPC | `acme-platform-dev-apse1-vpc` | `dev-apse1-vpc` |
| IAM Role | `acme-plat-dev-apse1-eks-role` | `dev-apse1-eks-role` |
| Security Group | `acme-platform-dev-apse1-eks-sg` | `dev-apse1-eks-sg` |

## Resource-Specific Naming

### S3 Buckets

**Format**: `{project}-{env}-{region}-{resource-type}`

**Rules**:
- Must be globally unique
- Lowercase only
- No underscores
- 3-63 characters

**Example**: `acme-platform-dev-apse1-state`

### DynamoDB Tables

**Format**: `{project}-{env}-{region}-{resource-type}`

**Rules**:
- Alphanumeric and hyphens only
- Max 255 characters

**Example**: `acme-platform-dev-apse1-locks`

### KMS Keys

**Alias Format**: `alias/{project}/{env}/{region}/{resource-type}`

**Rules**:
- Forward slashes allowed
- Max 256 characters

**Example**: `alias/acme-platform/dev/apse1/eks`

### IAM Roles

**Format**: `{project-short}-{env}-{region-short}-{resource-short}-role`

**Rules**:
- Max 64 characters
- Alphanumeric and `+=,.@-_` allowed
- Project name truncated to fit within limits

**Example**: `acme-plat-dev-apse1-eks-role`

### Security Groups

**Format**: `{project}-{env}-{region}-{resource-type}-sg`

**Rules**:
- Max 255 characters
- Alphanumeric and hyphens only

**Example**: `acme-platform-dev-apse1-eks-sg`

### CloudWatch Log Groups

**Format**: `/aws/{project}/{env}/{region}/{resource-type}`

**Rules**:
- Forward slashes allowed
- Max 512 characters

**Example**: `/aws/acme-platform/dev/apse1/eks`

### EKS Clusters

**Format**: `{env}-{region-short}-{resource-type}`

**Rules**:
- Max 100 characters
- Alphanumeric and hyphens only

**Example**: `dev-apse1-eks-cluster`

### VPCs

**Format**: `{project}-{env}-{region}-vpc`

**Example**: `acme-platform-dev-apse1-vpc`

### Subnets

**Format**: `{project}-{env}-{region}-{type}-subnet-{az}`

**Example**: `acme-platform-dev-apse1-public-subnet-1a`

## Region Shortening

To keep names within AWS limits, regions are shortened using a mapping defined in `common-env.hcl`:

| Full Region | Shortened |
|-------------|-----------|
| `ap-southeast-1` | `apse1` |
| `ap-southeast-2` | `apse2` |
| `ap-northeast-1` | `apne1` |
| `us-east-1` | `usea1` |
| `us-west-2` | `uswe2` |
| `eu-west-1` | `euwe1` |
| `eu-central-1` | `euce1` |

The region short code follows the pattern: `{prefix}{direction}{number}`
- `ap-southeast-1` → `ap` + `se` (southeast) + `1` = `apse1`
- `us-east-1` → `us` + `ea` (east) + `1` = `usea1`

See `live/common-env.hcl` for the complete region mapping.

## Environment Codes

| Environment | Code |
|-------------|------|
| Development | `dev` |
| Staging | `staging` |
| Production | `prod` |

## Layer Codes

| Layer | Code |
|-------|------|
| Layer 0 - Foundation | `layer0-foundation` |
| Layer 1 - Networking | `layer1-networking` |
| Layer 2 - Workloads | `layer2-workloads` |
| Layer 3 - Apps | `layer3-apps` |

## Usage in Terragrunt Configurations

The naming conventions are automatically available via `common-env.hcl`:

```hcl
include "root" {
  path = find_in_parent_folders()
}

locals {
  # Load global configuration
  global = read_terragrunt_config(find_in_parent_folders("common-env.hcl")).locals
  
  # Extract path components: live/{env}/{region}/...
  path_parts = split("/", get_terragrunt_dir())
  live_index = index(local.path_parts, "live")
  
  # Extract environment and region from path
  environment = local.path_parts[local.live_index + 1]
  region      = local.path_parts[local.live_index + 2]
  
  # Get region short code from global config
  region_short = try(local.global.region_short_map[local.region], "unknown")
  
  # Generate resource names
  bucket_name = "${local.global.project_name}-${local.environment}-${local.region_short}-state"
  table_name  = "${local.global.project_name}-${local.environment}-${local.region_short}-locks"
}
```

## Common Tags

Common tags are automatically applied via environment-specific configuration:

```hcl
# Load environment-specific configuration
live_dir = join("/", slice(local.path_parts, 0, local.live_index + 1))
env = read_terragrunt_config("${local.live_dir}/${local.environment}/env.hcl").locals

# Common tags
common_tags = merge(
  local.global.base_tags,
  {
    Environment = local.environment
    Region      = local.region
  },
  try(local.env.environment_tags, {})
)
```

Tags include:
- `Project` - Project name (e.g., `acme-platform`)
- `Environment` - Environment (dev, staging, prod)
- `Region` - AWS region
- `CreatedBy` - Always "Terraform"
- `ManagedBy` - Always "Terraform"
- Environment-specific tags (CostCenter, Owner, etc.)

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

## Best Practices

1. **Always use `common-env.hcl`**: Don't hardcode names or region mappings
2. **Follow the pattern**: Use the standard format for all resources
3. **Keep it short**: Use shortened region codes from `common-env.hcl`
4. **Be consistent**: Same resource type = same naming pattern
5. **Document exceptions**: If a resource can't follow the pattern, document why
6. **Extract from path**: Environment and region should be extracted from directory structure

## Examples

### Example 1: S3 Bucket for Terraform State

```hcl
locals {
  global = read_terragrunt_config(find_in_parent_folders("common-env.hcl")).locals
  environment = "dev"
  region = "ap-southeast-1"
  region_short = try(local.global.region_short_map[local.region], "unknown")
  
  bucket_name = "${local.global.project_name}-${local.environment}-${local.region_short}-state"
  # Result: "acme-platform-dev-apse1-state"
}
```

### Example 2: EKS Cluster

```hcl
locals {
  global = read_terragrunt_config(find_in_parent_folders("common-env.hcl")).locals
  environment = "dev"
  region = "ap-southeast-1"
  region_short = try(local.global.region_short_map[local.region], "unknown")
  
  cluster_name = "${local.environment}-${local.region_short}-eks-cluster"
  # Result: "dev-apse1-eks-cluster"
}
```

### Example 3: VPC

```hcl
locals {
  global = read_terragrunt_config(find_in_parent_folders("common-env.hcl")).locals
  environment = "dev"
  region = "ap-southeast-1"
  region_short = try(local.global.region_short_map[local.region], "unknown")
  
  vpc_name = "${local.global.project_name}-${local.environment}-${local.region_short}-vpc"
  # Result: "acme-platform-dev-apse1-vpc"
}
```

## Enforcement

Naming conventions are enforced via:
- `common-env.hcl` - Centralized project name and region mapping
- `live/{env}/env.hcl` - Environment-specific tags
- Path-based extraction - Environment and region extracted from directory structure
- Terraform validation rules - Validate names in modules
- CI/CD checks - Pre-commit hooks to validate naming

## Migration

If you have existing resources with different naming:
1. Document current naming
2. Plan migration to new convention
3. Update resources gradually
4. Update documentation
