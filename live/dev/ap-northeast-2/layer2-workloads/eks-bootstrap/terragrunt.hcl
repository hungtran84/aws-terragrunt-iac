# Layer 2 - Workloads: EKS Bootstrap Components
# Bootstrap components that must be deployed after EKS cluster is ready
# This includes Karpenter configuration (EC2NodeClass and NodePool)

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "."
}

# Direct dependency on EKS - Terragrunt handles the order
dependency "eks" {
  config_path = "../eks"
  
  # Mock outputs for plan/validate
  mock_outputs = {
    cluster_name                         = "mock-cluster"
    cluster_endpoint                     = "https://mock-endpoint.eks.ap-northeast-2.amazonaws.com"
    cluster_certificate_authority_data   = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t"
    cluster_oidc_issuer_url             = "https://oidc.eks.ap-northeast-2.amazonaws.com/id/MOCK"
    oidc_provider_arn                    = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/MOCK"
    karpenter_enabled                    = true
    karpenter_node_instance_profile_name = "mock-cluster-karpenter-node-profile"
    karpenter_node_iam_role_arn         = "arn:aws:iam::123456789012:role/mock-cluster-karpenter-node"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "vpc" {
  config_path = "../../layer1-networking/vpc"
  
  mock_outputs = {
    vpc_id             = "vpc-mock123456"
    private_subnet_ids = ["subnet-mock1", "subnet-mock2"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

locals {
  environment = "dev"
  region      = "ap-northeast-2"
}

inputs = {
  # EKS cluster info
  cluster_name                         = dependency.eks.outputs.cluster_name
  cluster_endpoint                     = dependency.eks.outputs.cluster_endpoint
  cluster_certificate_authority_data   = dependency.eks.outputs.cluster_certificate_authority_data
  cluster_oidc_issuer_url             = dependency.eks.outputs.cluster_oidc_issuer_url
  oidc_provider_arn                    = dependency.eks.outputs.oidc_provider_arn
  
  # Karpenter
  karpenter_enabled                    = dependency.eks.outputs.karpenter_enabled
  karpenter_node_instance_profile_name = dependency.eks.outputs.karpenter_node_instance_profile_name
  karpenter_node_iam_role_arn         = dependency.eks.outputs.karpenter_node_iam_role_arn
  
  # VPC info for future components
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  
  # Environment
  environment = local.environment
  region      = local.region
  
  # Component toggles
  enable_karpenter_config = true
  
  # Tags
  common_tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    Layer       = "layer2-workloads"
    Component   = "eks-bootstrap"
  }
}
