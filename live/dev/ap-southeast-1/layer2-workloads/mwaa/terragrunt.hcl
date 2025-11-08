# Layer 2 - Workloads: MWAA (Managed Workflows for Apache Airflow)
# Platform-level managed services - Example of custom module usage
include "root" {
  path = find_in_parent_folders()
}

# Using custom module as there's no official terraform-aws-modules for MWAA
terraform {
  source = "../../../../modules/custom-modules/mwaa"
}

# Dependencies on layer1-networking outputs would be referenced here
# dependency "vpc" {
#   config_path = "../layer1-networking/vpc"
# }

inputs = {
  environment           = "dev"
  aws_region            = "ap-southeast-1"
  mwaa_environment_name = "dev-airflow"
  airflow_version       = "2.8.1"
  environment_class     = "mw1.small"
  
  # These would come from layer1-networking outputs via dependency
  # security_group_ids = dependency.vpc.outputs.default_security_group_id
  # subnet_ids         = dependency.vpc.outputs.private_subnets
  security_group_ids = ["sg-xxxxxxxxx"]  # Placeholder - replace with actual SG IDs
  subnet_ids         = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]  # Placeholder - replace with actual subnet IDs
  
  max_workers = 10
  min_workers = 1
  
  log_level             = "INFO"
  webserver_access_mode = "PRIVATE_ONLY"
  
  common_tags = {
    Environment = "dev"
    CostCenter   = "development"
    Layer        = "layer2-workloads"
  }
}


