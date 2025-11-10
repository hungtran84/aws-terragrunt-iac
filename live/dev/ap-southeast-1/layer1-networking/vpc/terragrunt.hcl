# Layer 1 - Networking: VPC
# Core network and connectivity foundation
# Using official terraform-aws-modules VPC module

terraform {
  # Use git source with specific version to avoid deprecation warnings
  # Note: The deprecation warning about data.aws_region.current.name is from the module
  # and will be fixed in future versions. This is harmless but can be suppressed by
  # using a more recent version of the module.
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.8.0"
}

inputs = {
  name = "dev-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Environment = "dev"
    CostCenter   = "development"
    Layer        = "layer1-networking"
  }
}

