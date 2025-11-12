# Re-export all EKS module outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = module.eks.eks_managed_node_groups
}

# Additional outputs for company compliance
output "kms_key_id" {
  description = "KMS key ID used for EKS encryption"
  value       = module.eks.kms_key_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for EKS encryption"
  value       = module.eks.kms_key_arn
}

output "compliance_security_group_id" {
  description = "Security group ID for compliance requirements"
  value       = aws_security_group.eks_compliance.id
}

output "ebs_csi_driver_iam_role_arn" {
  description = "IAM role ARN for EBS CSI driver"
  value       = try(aws_iam_role.ebs_csi_driver[0].arn, null)
}

output "ebs_csi_driver_iam_role_name" {
  description = "IAM role name for EBS CSI driver"
  value       = try(aws_iam_role.ebs_csi_driver[0].name, null)
}

