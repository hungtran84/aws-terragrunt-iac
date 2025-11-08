# Common Configuration Module
# Provides shared configuration values, region mappings, and naming conventions

locals {
  # Region abbreviation mapping table
  region_short_map = {
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-southeast-3" = "apse3"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ap-northeast-3" = "apne3"
    "ap-south-1"     = "aps1"
    "ap-south-2"     = "aps2"
    "us-east-1"      = "useast1"
    "us-east-2"      = "useast2"
    "us-west-1"      = "uswest1"
    "us-west-2"      = "uswest2"
    "eu-west-1"      = "euwest1"
    "eu-west-2"      = "euwest2"
    "eu-west-3"      = "euwest3"
    "eu-central-1"   = "euc1"
    "eu-central-2"   = "euc2"
    "eu-north-1"     = "eun1"
    "ca-central-1"    = "cac1"
    "sa-east-1"      = "sae1"
  }
  
  # Project configuration
  project_name = "acme-platform"
  
  # Environment-specific tag mappings
  environment_tags = {
    "dev" = {
      CostCenter = "development"
      Owner      = "platform-team"
    }
    "staging" = {
      CostCenter = "staging"
      Owner      = "platform-team"
    }
    "prod" = {
      CostCenter = "production"
      Owner      = "platform-team"
      Backup     = "required"
    }
  }
  
  # Base tags applied to all resources
  base_tags = {
    CreatedBy = "Terraform"
    ManagedBy = "Terraform"
    Project   = local.project_name
  }
}

# Helper function to get region short code
# Usage: local.region_short_map[region] or try(local.region_short_map[region], "unknown")

