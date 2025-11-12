# Layer 2 - Workloads: Karpenter Bootstrap for EKS Cluster1
# Auto-scaling solution for Kubernetes nodes
# Using official terraform-aws-modules/eks Karpenter submodule

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Local values for Karpenter configuration
locals {
  # Extract path components for dynamic naming
  path_parts = split("/", get_terragrunt_dir())
  live_index = index(local.path_parts, "live")
  
  # Extract values from path (same logic as root.hcl)
  environment = local.path_parts[local.live_index + 1]  # dev
  region = local.path_parts[local.live_index + 2]       # ap-northeast-2
  
  # Load project name and region mapping from global config
  global = read_terragrunt_config(find_in_parent_folders("global-env.hcl")).locals
  region_short = try(local.global.region_short_map[local.region], local.region)
  
  # Cluster name (must match the EKS cluster)
  cluster_name = "acme-${local.environment}-${local.region_short}-eks-cluster1"
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/karpenter?ref=v21.8.0"
}

# Dependencies on EKS cluster
dependency "eks_cluster" {
  config_path = "../../cluster1"
  
  mock_outputs = {
    cluster_name                    = "acme-dev-apne2-eks-cluster1"
    cluster_endpoint               = "https://mock-cluster-endpoint.amazonaws.com"
    cluster_oidc_issuer_url       = "https://oidc.eks.ap-northeast-2.amazonaws.com/id/MOCKCLUSTERID"
    oidc_provider_arn             = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/MOCKCLUSTERID"
    node_security_group_id        = "sg-mock123456789"
    cluster_primary_security_group_id = "sg-mock987654321"
  }
}

inputs = {
  # Controls if resources should be created (affects nearly all resources)
  create = true
  
  # Cluster configuration (from EKS cluster dependency)
  cluster_name = dependency.eks_cluster.outputs.cluster_name
  
  # IRSA (IAM Roles for Service Accounts) configuration
  irsa_oidc_provider_arn = dependency.eks_cluster.outputs.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
  
  # Karpenter node pool configuration
  enable_karpenter_instance_profile = true
  
  # Security groups and networking
  # Karpenter nodes will use the cluster's security groups
  
  # Tagging for Karpenter-managed resources
  tags = {
    Component = "karpenter"
    Service   = "auto-scaling"
    
    # Karpenter discovery tags (required for node discovery)
    "karpenter.sh/discovery" = dependency.eks_cluster.outputs.cluster_name
  }
  
  # Instance profile and role configuration
  create_iam_role = true
  iam_role_name   = "${local.environment}-${local.region_short}-karpenter-node"
  
  # Use inline policy instead of managed policy to avoid size limits
  enable_inline_policy = true
  
  # Additional policies for Karpenter nodes
  iam_role_additional_policies = {
    AmazonEKSWorkerNodePolicy         = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEKS_CNI_Policy             = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonSSMManagedInstanceCore      = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}