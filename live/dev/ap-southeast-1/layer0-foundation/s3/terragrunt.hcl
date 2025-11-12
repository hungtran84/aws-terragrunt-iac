# Layer 0 - Foundation: S3 Bucket for Terraform State
# Note: This must be deployed manually first (chicken-and-egg problem)

# Load configuration files
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
  
  # Load environment-specific configuration
  # Path: live/{env}/env.hcl
  live_dir = join("/", slice(local.path_parts, 0, local.live_index + 1))
  env = read_terragrunt_config("${local.live_dir}/${local.environment}/env.hcl").locals
  
  # Naming convention
  bucket_name = "${local.global.project_name}-${local.environment}-${local.region_short}-state"
  
  # Common tags
  common_tags = merge(
    local.global.base_tags,
    {
      Environment = local.environment
      Region      = local.region
    },
    try(local.env.environment_tags, {})
  )
}

# Use official terraform-aws-modules for S3 bucket
# 
# KNOWN ISSUE: Deprecation warning about data.aws_region.current.name
# This warning comes from the module's internal code (line 607 in main.tf) where it uses
# data.aws_region.current.name instead of data.aws_region.current.id.
# This is a known issue in the terraform-aws-modules/terraform-aws-s3-bucket module that
# will be fixed by the module maintainers in a future release.
# The warning is harmless and does not affect functionality - it's just informational.
#
# To track the fix: https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/issues
terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v4.4.0"
}

# Override remote_state to use local backend for foundation layer
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

# Generate provider configuration
# Note: required_providers is already defined in the module's versions.tf
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# Provider configuration for S3 bucket
# Note: required_providers is already defined in the module's versions.tf
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

inputs = {
  bucket = local.bucket_name
  
  versioning = {
    enabled = true
  }
  
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  tags = local.common_tags
}
