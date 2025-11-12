# Variables for EKS Bootstrap module

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data (base64 encoded)"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster OIDC provider"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for future components"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for future components"
  type        = list(string)
}

################################################################################
# Karpenter Configuration
################################################################################

variable "karpenter_enabled" {
  description = "Whether Karpenter is enabled in the EKS cluster"
  type        = bool
  default     = false
}

variable "enable_karpenter_config" {
  description = "Enable Karpenter configuration (EC2NodeClass and NodePool)"
  type        = bool
  default     = true
}

variable "karpenter_node_instance_profile_name" {
  description = "Instance profile name for Karpenter nodes (from EKS module)"
  type        = string
  default     = ""
}

variable "karpenter_node_iam_role_arn" {
  description = "IAM role ARN for Karpenter nodes (from EKS module)"
  type        = string
  default     = ""
}

variable "karpenter_nodepool_limits" {
  description = "Resource limits for Karpenter NodePool"
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "100"
    memory = "400Gi"
  }
}

variable "karpenter_instance_categories" {
  description = "EC2 instance categories allowed for Karpenter"
  type        = list(string)
  default     = ["c", "m", "r", "t"]
}

variable "karpenter_instance_generation" {
  description = "Minimum EC2 instance generation (greater than this value)"
  type        = string
  default     = "2"
}

variable "karpenter_capacity_type" {
  description = "Capacity type for Karpenter nodes (on-demand or spot)"
  type        = list(string)
  default     = ["on-demand"]
}

################################################################################
# Common Tags
################################################################################

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
