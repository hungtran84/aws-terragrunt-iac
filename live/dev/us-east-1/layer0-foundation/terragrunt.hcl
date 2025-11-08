# Layer 0 - Foundation
# Bootstrap infrastructure: S3 bucket for Terraform state, DynamoDB lock table, etc.
# Note: This layer must be deployed manually first (chicken-and-egg problem)
include "root" {
  path = find_in_parent_folders()
}

# Example: Using official terraform-aws-modules for S3 bucket
terraform {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"
}

inputs = {
  environment = "dev"
  aws_region  = "us-east-1"
  
  bucket = "terraform-state-dev-us-east-1"
  
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
  
  common_tags = {
    Environment = "dev"
    CostCenter   = "development"
    Layer        = "layer0-foundation"
  }
}

