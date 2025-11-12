# Layer 2 - Workloads: MWAA (Managed Workflows for Apache Airflow)
# Platform-level managed services - Example of custom module usage

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Using custom module as there's no official terraform-aws-modules for MWAA
terraform {
  source = "../../../../../modules/custom-modules/mwaa"
}

# Dependencies on layer1-networking outputs
dependency "vpc" {
  config_path = "../../layer1-networking/vpc/vpc1"
  
  mock_outputs = {
    vpc_id                   = "vpc-12345678"
    private_subnets         = ["subnet-12345678", "subnet-87654321"]
    default_security_group_id = "sg-12345678"
  }
}

inputs = {
  environment           = "dev"
  aws_region            = "ap-northeast-2"
  mwaa_environment_name = "dev-airflow"
  airflow_version       = "2.8.1"
  environment_class     = "mw1.small"
  
  # VPC configuration from layer1-networking outputs
  security_group_ids = [dependency.vpc.outputs.default_security_group_id]
  subnet_ids         = dependency.vpc.outputs.private_subnets
  
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


