# Layer 3 - Add-ons & Applications: ArgoCD
# Application enablement layer - tools and app deployments on top of workloads

# Note: ArgoCD is typically deployed via Helm/ArgoCD itself (GitOps)
# This is a placeholder for any ArgoCD infrastructure requirements
terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/kubernetes-addons?ref=v20.15.0"
}

inputs = {
  environment = "dev"
  aws_region  = "ap-southeast-1"
  
  # EKS cluster configuration - would reference layer2-workloads outputs
  # cluster_name = dependency.eks.outputs.cluster_name
  
  # ArgoCD addon configuration
  enable_argocd = true
  
  common_tags = {
    Environment = "dev"
    CostCenter   = "development"
    Layer        = "layer3-apps"
  }
}


