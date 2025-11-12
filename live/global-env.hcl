# Global Configuration
# Shared configuration values used across all environments and regions

locals {
  # Project configuration
  project_name = "acme-platform"
  
  # Base tags applied to all resources
  base_tags = {
    CreatedBy = "Terraform"
    ManagedBy = "Terraform"
    Project   = local.project_name
  }
  
  # AWS Region to short name mapping
  # Maps full AWS region names to their short codes
  region_short_map = {
    # Asia Pacific
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-southeast-3" = "apse3"
    "ap-southeast-4" = "apse4"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ap-northeast-3" = "apne3"
    "ap-south-1"     = "apso1"
    "ap-south-2"     = "apso2"
    "ap-east-1"      = "ape1"
    
    # US
    "us-east-1"      = "usea1"
    "us-east-2"      = "usea2"
    "us-west-1"      = "uswe1"
    "us-west-2"      = "uswe2"
    
    # Europe
    "eu-west-1"      = "euwe1"
    "eu-west-2"      = "euwe2"
    "eu-west-3"      = "euwe3"
    "eu-central-1"   = "euce1"
    "eu-central-2"   = "euce2"
    "eu-north-1"     = "euno1"
    "eu-south-1"     = "euso1"
    "eu-south-2"     = "euso2"
    
    # Canada
    "ca-central-1"    = "cace1"
    "ca-west-1"      = "cawe1"
    
    # South America
    "sa-east-1"      = "saea1"
    
    # Middle East
    "me-south-1"     = "meso1"
    "me-central-1"  = "mece1"
    
    # Africa
    "af-south-1"     = "afso1"
    
    # Israel
    "il-central-1"  = "ilce1"
    
    # China
    "cn-north-1"     = "cnno1"
    "cn-northwest-1" = "cnnw1"
  }
}