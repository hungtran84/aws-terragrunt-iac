# Layer 0 - Foundation: Remote State
# Creates S3 bucket for Terraform state storage and DynamoDB table for state locking
# Note: This must be deployed manually first (chicken-and-egg problem)
include "root" {
  path = find_in_parent_folders()
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

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.83.0"
    }
  }
}

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

# Generate main Terraform code using official modules
generate "main" {
  path      = "main.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# KMS Key for S3 bucket encryption
resource "aws_kms_key" "state_bucket_key" {
  description             = "KMS key for S3 backend state bucket encryption"
  deletion_window_in_days = 7
  
  tags = var.tags
}

resource "aws_kms_alias" "state_bucket_key_alias" {
  name          = "alias/${var.bucket_name}-key"
  target_key_id = aws_kms_key.state_bucket_key.key_id
}

# S3 Bucket for Terraform state storage using official module
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket = var.bucket_name

  # Enable versioning
  versioning = {
    enabled = true
  }

  # Enable KMS encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.state_bucket_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Ownership controls
  ownership_controls = {
    rule = {
      object_ownership = "BucketOwnerEnforced"
    }
  }

  tags = var.tags
}

# DynamoDB Table for Terraform state locking using official module
module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 5.2"

  name = var.dynamodb_table_name

  # Required attributes for Terraform state locking: LockID (String)
  hash_key = "LockID"
  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  # Billing mode: Provisioned (as per example)
  billing_mode = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  # Point-in-time recovery (PITR) - recommended for production
  point_in_time_recovery_enabled = var.enable_point_in_time_recovery

  # Server-side encryption
  server_side_encryption_enabled = true
  server_side_encryption_kms_key_enabled = false  # Use AWS managed key

  # Deletion protection - prevent accidental deletion
  deletion_protection_enabled = var.enable_deletion_protection

  tags = var.tags
}
EOF
}

# Generate variables file
generate "variables" {
  path      = "variables.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB table"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for DynamoDB table"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
EOF
}

# Generate outputs file
generate "outputs" {
  path      = "outputs.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# KMS Key Outputs
output "kms_key_id" {
  description = "ID of the KMS key for S3 bucket encryption"
  value       = aws_kms_key.state_bucket_key.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for S3 bucket encryption"
  value       = aws_kms_key.state_bucket_key.arn
}

# S3 Bucket Outputs
output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

# DynamoDB Table Outputs
output "dynamodb_table_id" {
  description = "ID of the DynamoDB table"
  value       = module.dynamodb_table.dynamodb_table_id
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb_table.dynamodb_table_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb_table.dynamodb_table_name
}
EOF
}

# Access inputs from included root config
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
  
  # Service configuration (adaptable to your naming convention)
  service_type = "terragrunt-layers"
  service_domain = "iac"
  region_short = replace(replace(replace(replace(local.region, "ap-southeast-1", "apse1"), "us-east-1", "useast1"), "us-west-2", "uswest2"), "eu-west-1", "euwest1")
  
  # Compute naming convention (following your example pattern)
  naming_convention = {
    s3_bucket = "${local.service_type}-${local.service_domain}-${local.region_short}-${local.environment}-tfstate"
    dynamodb_table = "${local.service_type}-${local.service_domain}-${local.region_short}-${local.environment}-tfstate-lock"
  }
  
  # Compute common tags
  common_tags = merge(
    {
      CreatedBy   = "Terraform"
      Project     = local.service_type
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
  # S3 bucket configuration
  bucket_name = local.naming_convention.s3_bucket
  
  # DynamoDB table configuration
  dynamodb_table_name = local.naming_convention.dynamodb_table
  
  # DynamoDB settings based on environment
  enable_point_in_time_recovery = local.environment == "prod" ? true : false
  enable_deletion_protection    = local.environment == "prod" ? true : false
  
  # Common tags
  tags = local.common_tags
}
