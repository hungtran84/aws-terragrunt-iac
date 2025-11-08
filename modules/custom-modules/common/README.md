# Common Configuration Module

This module provides shared configuration values, mappings, and conventions used across all Terragrunt configurations.

## Contents

- **Region Abbreviation Mapping**: Maps full AWS region names to short codes
- **Project Configuration**: Project name and settings
- **Environment Tags**: Environment-specific tag mappings
- **Base Tags**: Common tags applied to all resources

## Usage

Load the common configuration in your `terragrunt.hcl`:

```hcl
locals {
  # Find repo root
  repo_root = get_parent_terragrunt_dir()
  
  # Load common configuration
  common = read_terragrunt_config("${local.repo_root}/modules/custom-modules/common/common.hcl").locals
  
  # Use common values
  region_short = try(local.common.region_short_map[local.region], "unknown")
  project_name = local.common.project_name
  common_tags = merge(
    local.common.base_tags,
    { Environment = local.environment },
    try(local.common.environment_tags[local.environment], {})
  )
}
```

## Region Mapping

The `region_short_map` provides abbreviations for AWS regions:

- `ap-southeast-1` → `apse1`
- `us-east-1` → `useast1`
- `eu-west-1` → `euwest1`
- ... and more

## Environment Tags

Environment-specific tags are defined in `environment_tags`:

- `dev`: CostCenter = "development", Owner = "platform-team"
- `staging`: CostCenter = "staging", Owner = "platform-team"
- `prod`: CostCenter = "production", Owner = "platform-team", Backup = "required"

## Adding New Regions

To add a new region, simply add it to the `region_short_map` in `common.hcl`:

```hcl
region_short_map = {
  "ap-southeast-1" = "apse1"
  "your-new-region" = "yourcode"
  ...
}
```

