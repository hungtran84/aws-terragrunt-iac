################################################################################
# Karpenter Outputs
################################################################################

output "karpenter_ec2nodeclass_name" {
  description = "Karpenter EC2NodeClass name"
  value       = var.enable_karpenter_config ? module.karpenter[0].ec2nodeclass_name : null
}

output "karpenter_nodepool_name" {
  description = "Karpenter NodePool name"
  value       = var.enable_karpenter_config ? module.karpenter[0].nodepool_name : null
}

output "bootstrap_components" {
  description = "Enabled bootstrap components"
  value = {
    karpenter_config = var.enable_karpenter_config
  }
}
