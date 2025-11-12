# Root Terragrunt configuration
# This file contains shared configuration that can be inherited by all environments and layers

# Common configuration (naming conventions, tags, etc.)
# Merged from common.hcl to avoid nested includes
locals {
  # Extract path components for naming
  # Path format: live/{env}/{region}/{layer}/{resource}
  path_parts = split("/", get_terragrunt_dir())
  path_len = length(local.path_parts)
  
  # Find the index of "live" in the path to handle absolute paths correctly
  live_index = index(local.path_parts, "live")
  
  # Get environment from path (live/{env}/...) - live_index + 1
  environment = try(
    local.path_parts[local.live_index + 1],
    get_env("ENVIRONMENT", "dev")
  )
  
  # Get region from path (live/{env}/{region}/...) - live_index + 2
  region = try(
    local.path_parts[local.live_index + 2],
    get_env("AWS_REGION", "us-east-1")
  )
  
  # Get layer from path (live/{env}/{region}/{layer}/...) - live_index + 3
  layer = try(
    local.path_parts[local.live_index + 3],
    "unknown"
  )
  
  # Get resource name from path (live/{env}/{region}/{layer}/{resource}) - live_index + 4
  resource_name = try(
    local.path_parts[local.live_index + 4],
    "default"
  )
  
  # Project name
  project_name = "acme-platform"
  
  # Load global configuration for region mapping
  global = read_terragrunt_config(find_in_parent_folders("global-env.hcl")).locals
  
  # Region shortening - use the global region mapping
  region_short = try(local.global.region_short_map[local.region], local.region)
  
  # Standard resource name
  resource_name_standard = "${local.project_name}-${local.environment}-${local.region_short}-${local.resource_name}"
  
  # Short resource name
  short_name = "${local.environment}-${local.region_short}-${local.resource_name}"
  
  # Common tags applied to all resources
  common_tags_base = {
    Project     = local.project_name
    Environment = local.environment
    Region      = local.region
    Layer       = local.layer
    ManagedBy   = "Terraform"
    Repository  = "terragrunt-layers"
  }
  
  # Environment-specific tags
  environment_tags_dev = {
    CostCenter = "development"
    Owner      = "platform-team"
  }
  
  environment_tags_staging = {
    CostCenter = "staging"
    Owner      = "platform-team"
  }
  
  environment_tags_prod = {
    CostCenter = "production"
    Owner      = "platform-team"
    Backup     = "required"
  }
  
  # Final tags based on environment
  common_tags = local.environment == "dev" ? merge(local.common_tags_base, local.environment_tags_dev) : (
    local.environment == "staging" ? merge(local.common_tags_base, local.environment_tags_staging) : 
    merge(local.common_tags_base, local.environment_tags_prod)
  )
}


# Generate backend configuration for all modules
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "s3" {}
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
# Note: Layer 0 Foundation must be deployed first to create the S3 bucket and DynamoDB table
remote_state {
  backend = "s3"
  config = {
    # Use the same naming convention as layer0-foundation
    bucket         = get_env("TF_STATE_BUCKET", "${local.project_name}-${local.environment}-${local.region_short}-state")
    key            = "${path_relative_to_include()}/terraform.tfstate"  
    region         = local.region
    encrypt        = true
    dynamodb_table = get_env("TF_LOCK_TABLE", "${local.project_name}-${local.environment}-${local.region_short}-locks")
  }
}

# Note: Backend configuration is handled by individual modules as needed
# - Layer0 foundation modules use local backend (they create the S3 bucket)  
# - Other modules should generate their own backend configuration for S3

# Inputs that can be overridden by child configurations
inputs = {
  # Naming conventions
  naming_convention = {
    resource_name        = local.resource_name_standard
    short_name          = local.short_name
    s3_bucket           = "${local.project_name}-${local.environment}-${local.region_short}-${local.resource_name}"
    dynamodb_table      = "${local.project_name}-${local.environment}-${local.region_short}-${local.resource_name}"
    kms_alias           = "alias/${local.project_name}/${local.environment}/${local.region_short}/${local.resource_name}"
    iam_role            = "${substr(local.project_name, 0, 8)}-${local.environment}-${substr(local.region_short, 0, 6)}-${substr(local.resource_name, 0, 10)}-role"
    security_group      = "${local.project_name}-${local.environment}-${local.region_short}-${local.resource_name}-sg"
    cloudwatch_log_group = "/aws/${local.project_name}/${local.environment}/${local.region_short}/${local.resource_name}"
    eks_cluster         = "${local.environment}-${local.region_short}-${local.resource_name}"
    vpc                 = "${local.project_name}-${local.environment}-${local.region_short}-vpc"
  }
  
  # Common tags (automatically includes environment-specific tags)
  common_tags = local.common_tags
  
  # Environment and region
  environment  = local.environment
  aws_region   = local.region
  layer        = local.layer
  project_name = local.project_name
}
