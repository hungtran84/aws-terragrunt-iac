# Layer 1 - Networking: VPC
# Core network and connectivity foundation
# Using official terraform-aws-modules VPC module

# Include root configuration to inherit provider, remote state, and common variables
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Simple local values for this VPC
locals {
  # Extract environment and region from path for naming
  path_parts = split("/", get_terragrunt_dir())
  live_index = index(local.path_parts, "live")
  environment = local.path_parts[local.live_index + 1]
  region = local.path_parts[local.live_index + 2]
  
  # Load project name from global config
  global = read_terragrunt_config(find_in_parent_folders("global-env.hcl")).locals
  project_name = local.global.project_name
  
  # Extract VPC instance name from path (e.g., "vpc1")
  vpc_instance = local.path_parts[local.live_index + 5]  # live/{env}/{region}/{layer}/{resource}/{instance}
  
  # VPC name including instance identifier
  vpc_name = "${local.project_name}-${local.environment}-vpc-${local.vpc_instance}"
}

terraform {
  # Use git source with specific version to avoid deprecation warnings
  # Note: The deprecation warning about data.aws_region.current.name is from the module  
  # and will be fixed in future versions. This is harmless but can be suppressed by
  # using a more recent version of the module.
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.8.0"
}

inputs = {
  # Use VPC name from local values
  name = local.vpc_name
  cidr = "10.0.0.0/16"
  
  # Build AZ names from region
  azs             = ["${local.region}a", "${local.region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Basic tags - additional tags will come from provider default_tags
  tags = {
    Layer = "layer1-networking"
  }
}

