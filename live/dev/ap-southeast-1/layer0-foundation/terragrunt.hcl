# Layer 0 - Foundation
# Bootstrap infrastructure: S3 bucket for Terraform state, DynamoDB lock table, etc.
# Note: This layer must be deployed manually first (chicken-and-egg problem)
include "root" {
  path = find_in_parent_folders()
}

# Example: Using official terraform-aws-modules for S3 bucket
terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v4.1.0"
}

# Override remote_state to use local backend for foundation layer
# This avoids the chicken-and-egg problem (can't store state in S3 if S3 doesn't exist yet)
remote_state {
  backend = "local"
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}

# Generate backend block for local state
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF
}

# Override provider generation - module already has required_providers in versions.tf
# Generate only the provider block without the terraform/required_providers block
# Use values from locals instead of variables
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# Provider configuration for foundation layer
# Note: required_providers is already defined in the module's versions.tf
# We only generate the provider block here to avoid duplicate required_providers
provider "aws" {
  region = "${local.region}"
  
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = "${local.environment}"
      Project     = "terragrunt-layers"
    }
  }
}
EOF
}

# Access inputs from included root config
# Inputs from included files are merged, so we can reference them directly
# But we need to compute them here since they depend on locals from the parent
locals {
  # Recompute naming convention based on path (same logic as root)
  # Path format: .../live/{env}/{region}/{layer}/{resource}
  path_parts = split("/", get_terragrunt_dir())
  # Find the index of "live" in the path
  live_index = try(index(local.path_parts, "live"), -1)
  # Extract components relative to "live"
  environment = local.live_index >= 0 && local.live_index + 1 < length(local.path_parts) ? local.path_parts[local.live_index + 1] : "dev"
  region = local.live_index >= 0 && local.live_index + 2 < length(local.path_parts) ? local.path_parts[local.live_index + 2] : "ap-southeast-1"
  layer = local.live_index >= 0 && local.live_index + 3 < length(local.path_parts) ? local.path_parts[local.live_index + 3] : "layer0-foundation"
  resource_name = local.live_index >= 0 && local.live_index + 4 < length(local.path_parts) ? local.path_parts[local.live_index + 4] : "state"
  project_name = "terragrunt-layers"
  region_short = replace(replace(replace(replace(local.region, "ap-southeast-1", "apse1"), "us-east-1", "useast1"), "us-west-2", "uswest2"), "eu-west-1", "euwest1")
  
  # Compute naming convention
  naming_convention = {
    s3_bucket = "${local.project_name}-${local.environment}-${local.region_short}-${local.resource_name}"
    dynamodb_table = "${local.project_name}-${local.environment}-${local.region_short}-locks"
  }
  
  # Compute common tags
  common_tags = merge(
    {
      Project     = local.project_name
      Environment = local.environment
      Region      = local.region
      Layer       = local.layer
      ManagedBy   = "Terraform"
      Repository  = "terragrunt-layers"
    },
    local.environment == "dev" ? {
      CostCenter = "development"
      Owner      = "platform-team"
    } : local.environment == "staging" ? {
      CostCenter = "staging"
      Owner      = "platform-team"
    } : {
      CostCenter = "production"
      Owner      = "platform-team"
      Backup     = "required"
    }
  )
}

inputs = {
  # Use naming convention computed from path
  bucket = local.naming_convention.s3_bucket
  
  # Enable versioning
  versioning = {
    enabled = true
  }
  
  # Enable encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  
  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  # Use common tags computed from path
  tags = local.common_tags
}

# Note: Naming conventions and tags are automatically available via common.hcl include
# Access them via: dependency.common.outputs.naming_convention.*
# Or directly via inputs: var.naming_convention.*

