# Layer 2 - Workloads: EKS Cluster (Enterprise Wrapper)
# Platform-level managed services and compute layer
# Using custom enterprise wrapper module that enforces company security policies

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Local values for this EKS cluster
locals {
  # Extract path components for dynamic naming
  path_parts = split("/", get_terragrunt_dir())
  live_index = index(local.path_parts, "live")
  
  # Extract values from path (same logic as root.hcl)
  environment = local.path_parts[local.live_index + 1]  # dev
  region = local.path_parts[local.live_index + 2]       # ap-northeast-2
  eks_instance = local.path_parts[local.live_index + 5] # cluster1
  
  # Load project name and region mapping from global config (same as root.hcl)
  global = read_terragrunt_config(find_in_parent_folders("global-env.hcl")).locals
  project_name = local.global.project_name
  
  # Region shortening - use the global region mapping (same logic as root.hcl)
  region_short = try(local.global.region_short_map[local.region], local.region)
  
  # EKS cluster name using dynamic values with shortened region (matches root.hcl logic)
  cluster_name = "${local.project_name}-${local.environment}-${local.region_short}-eks-${local.eks_instance}"
}

terraform {
  source = "../../../../../../modules/custom-modules/eks-enterprise"
}

# Dependencies on layer1-networking outputs
dependency "vpc" {
  config_path = "../../../layer1-networking/vpc/vpc1"
  
  mock_outputs = {
    vpc_id          = "vpc-12345678"
    private_subnets = ["subnet-12345678", "subnet-87654321"]
  }
}

inputs = {
  # Module-specific configuration (environment, aws_region, project_name come from root.hcl automatically)
  cluster_name    = local.cluster_name
  cluster_version = "1.28"
  
  # VPC configuration from layer1-networking outputs
  vpc_id             = dependency.vpc.outputs.vpc_id
  subnet_ids         = dependency.vpc.outputs.private_subnets
  private_subnet_ids = dependency.vpc.outputs.private_subnets
  
  # Company policy: Public access disabled by default
  allow_public_access = false
  
  # Node groups with company security standards enforced
  node_groups = {
    main = {
      instance_types = ["t3.large", "t3.xlarge"]  # Must be in allowed_instance_types
      disk_size      = 50
      min_size       = 2  # Company policy: minimum 2 nodes
      max_size       = 10
      desired_size   = 3
      ami_type       = "AL2_x86_64"  # Company policy: AL2 enforced
      labels = {
        "node-type" = "general"
      }
      tags = {}
    }
  }
  
  # Merge root common_tags with EKS-specific tags
  # Note: common_tags from root.hcl already include Environment, CostCenter, Layer, etc.
}

