# Layer 2 - Workloads: EKS Cluster (Enterprise Wrapper)
# Platform-level managed services and compute layer
# Using custom enterprise wrapper module that enforces company security policies

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../modules/custom-modules/eks-enterprise"
}

# Dependencies on layer1-networking outputs
dependency "vpc" {
  config_path = "../../layer1-networking/vpc"
  
  mock_outputs = {
    vpc_id          = "vpc-12345678"
    private_subnets = ["subnet-12345678", "subnet-87654321"]
  }
}

inputs = {
  environment     = "dev"
  aws_region      = "ap-northeast-2"
  cluster_name    = "dev-eks-cluster"
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
  
  # Karpenter Bootstrap Integration
  enable_karpenter             = true
  karpenter_namespace          = "karpenter"
  karpenter_chart_version      = "1.1.0"
  karpenter_replicas           = 2
  karpenter_controller_resources = {
    requests = {
      cpu    = "1"
      memory = "1Gi"
    }
    limits = {
      cpu    = "1"
      memory = "1Gi"
    }
  }
  
  common_tags = {
    Environment = "dev"
    CostCenter   = "development"
    Layer        = "layer2-workloads"
  }
}

