# EKS Bootstrap Module
# Bootstrap components for EKS cluster including Karpenter configuration

terraform {
  required_version = ">= 1.9"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

# Get EKS cluster authentication token
data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Configure kubectl provider
provider "kubectl" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

################################################################################
# Karpenter Configuration Module
################################################################################

module "karpenter" {
  source = "./karpenter"
  count  = var.enable_karpenter_config ? 1 : 0

  cluster_name                         = var.cluster_name
  environment                          = var.environment
  karpenter_node_instance_profile_name = var.karpenter_node_instance_profile_name
}
