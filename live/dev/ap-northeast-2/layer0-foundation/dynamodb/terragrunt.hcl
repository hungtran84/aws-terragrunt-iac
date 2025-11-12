# Layer 0 - Foundation: DynamoDB Table for Terraform State Locking
# Note: This must be deployed manually first (chicken-and-egg problem)

# Load configuration files
locals {
  # Load global configuration
  global = read_terragrunt_config(find_in_parent_folders("global-env.hcl")).locals
  
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
  table_name = "${local.global.project_name}-${local.environment}-${local.region_short}-locks"
  
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

# Use official terraform-aws-modules for DynamoDB table
terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-dynamodb-table.git?ref=v5.2.0"
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
# Provider configuration for DynamoDB table
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
  name = local.table_name
  
  hash_key = "LockID"
  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]
  
  billing_mode = "PAY_PER_REQUEST"
  
  point_in_time_recovery_enabled = local.environment == "prod" ? true : false
  
  server_side_encryption_enabled = true
  server_side_encryption_kms_key_enabled = false
  
  deletion_protection_enabled = local.environment == "prod" ? true : false
  
  tags = local.common_tags
}
