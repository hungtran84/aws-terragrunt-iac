variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "karpenter_node_instance_profile_name" {
  description = "Instance profile name for Karpenter nodes"
  type        = string
}
