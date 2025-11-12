# Outputs for EKS Bootstrap module

################################################################################
# Karpenter Outputs
################################################################################

output "karpenter_config_enabled" {
  description = "Whether Karpenter configuration is enabled"
  value       = local.karpenter_enabled
}

output "karpenter_ec2nodeclass_name" {
  description = "Karpenter EC2NodeClass name"
  value       = local.karpenter_enabled ? "default" : null
}

output "karpenter_nodepool_names" {
  description = "List of Karpenter NodePool names"
  value       = local.karpenter_enabled ? ["default"] : []
}

output "karpenter_node_role" {
  description = "IAM role name for Karpenter nodes"
  value       = local.karpenter_enabled ? "${var.cluster_name}-karpenter-node" : null
}

################################################################################
# Bootstrap Status
################################################################################

output "bootstrap_components" {
  description = "Status of bootstrap components"
  value = {
    karpenter_config = {
      enabled       = local.karpenter_enabled
      ec2nodeclass  = local.karpenter_enabled ? "default" : null
      nodepools     = local.karpenter_enabled ? ["default"] : []
      capacity_type = var.karpenter_capacity_type
    }
  }
}

output "cluster_info" {
  description = "EKS cluster information"
  value = {
    name        = var.cluster_name
    environment = var.environment
    region      = var.region
  }
}
