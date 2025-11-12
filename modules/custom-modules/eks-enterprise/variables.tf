variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version (minimum 1.28 enforced by company policy)"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[89]|[3-9][0-9])", var.cluster_version))
    error_message = "Cluster version must be 1.28 or higher (company policy)."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for node groups (company policy: nodes must be in private subnets)"
  type        = list(string)
}

variable "node_groups" {
  description = "Map of EKS managed node group definitions"
  type = map(object({
    instance_types = list(string)
    disk_size      = number
    min_size       = number
    max_size       = number
    desired_size   = number
    ami_type       = string
    labels         = map(string)
    tags           = map(string)
  }))
  default = {}
}

# Company Security Policies
variable "allow_public_access" {
  description = "Allow public access to cluster endpoint (company policy: default false)"
  type        = bool
  default     = false
}

variable "allowed_public_cidrs" {
  description = "CIDR blocks allowed to access public endpoint (if enabled)"
  type        = list(string)
  default     = []
}

variable "allowed_instance_types" {
  description = "List of allowed instance types (company policy)"
  type        = list(string)
  default = [
    "t3.medium",
    "t3.large",
    "t3.xlarge",
    "m5.large",
    "m5.xlarge",
    "m5.2xlarge",
    "c5.large",
    "c5.xlarge"
  ]
}

variable "default_instance_type" {
  description = "Default instance type if specified type is not allowed"
  type        = string
  default     = "t3.medium"
}

variable "min_node_count" {
  description = "Minimum node count per node group (company policy)"
  type        = number
  default     = 2
}

variable "ami_type" {
  description = "AMI type for nodes (company policy: enforce AL2)"
  type        = string
  default     = "AL2_x86_64"

  validation {
    condition     = contains(["AL2_x86_64", "AL2_ARM_64", "AL2_x86_64_GPU"], var.ami_type)
    error_message = "AMI type must be AL2_x86_64, AL2_ARM_64, or AL2_x86_64_GPU (company policy)."
  }
}

variable "enabled_log_types" {
  description = "List of control plane logging types (company requirement: all enabled)"
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days (company policy: minimum 30 days)"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30
    error_message = "Log retention must be at least 30 days (company policy)."
  }
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days (company policy: minimum 7 days)"
  type        = number
  default     = 7

  validation {
    condition     = var.kms_deletion_window >= 7
    error_message = "KMS deletion window must be at least 7 days (company policy)."
  }
}

variable "allowed_egress_cidrs" {
  description = "CIDR blocks allowed for egress traffic (company security policy)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Can be restricted to company endpoints
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Karpenter Bootstrap Configuration
################################################################################

variable "enable_karpenter" {
  description = "Enable Karpenter installation as part of EKS bootstrap"
  type        = bool
  default     = false
}

variable "karpenter_namespace" {
  description = "Kubernetes namespace for Karpenter"
  type        = string
  default     = "karpenter"
}

variable "karpenter_chart_version" {
  description = "Karpenter Helm chart version"
  type        = string
  default     = "1.1.0"
}

variable "karpenter_replicas" {
  description = "Number of Karpenter controller replicas for high availability"
  type        = number
  default     = 2
}

variable "karpenter_controller_resources" {
  description = "Resource requests and limits for Karpenter controller pod"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "1"
      memory = "1Gi"
    }
    limits = {
      cpu    = "1"
      memory = "1Gi"
    }
  }
}

variable "aws_region" {
  description = "AWS region for Karpenter configuration"
  type        = string
  default     = ""
}
