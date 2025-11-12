# EKS Enterprise Module
# Wrapper around official terraform-aws-modules/eks/aws with company-specific security policies
# and stricter defaults
terraform {
  required_version = ">= 1.0"

  # Backend configuration - will be configured by Terragrunt
  # backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
  }
}

# Use the official EKS module as the base
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = var.cluster_name
  # Security: Enforce minimum cluster version (company policy)
  cluster_version = var.cluster_version >= "1.28" ? var.cluster_version : "1.28"

  # Network configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Security: Enforce private endpoint (company policy)
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.allow_public_access
  cluster_endpoint_public_access_cidrs = var.allow_public_access ? var.allowed_public_cidrs : []

  # Security: Enable encryption
  cluster_enabled_log_types              = var.enabled_log_types
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  # Security: Enable encryption at rest
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  # Use the KMS key from the EKS module instead of custom key
  create_kms_key                = true
  kms_key_description           = "EKS cluster encryption key for ${var.cluster_name}"
  kms_key_enable_default_policy = true

  # Security: Enable control plane logging (company requirement)
  enable_cluster_creator_admin_permissions = false

  # Node groups with company security standards
  eks_managed_node_groups = {
    for k, v in var.node_groups : k => {
      # Security: Enforce minimum instance types (company policy)
      instance_types = [for it in v.instance_types :
        contains(var.allowed_instance_types, it) ? it : var.default_instance_type
      ]

      # Security: Enforce disk encryption
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = v.disk_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # Security: Enforce IMDSv2 (company security policy)
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required" # Enforce IMDSv2
        http_put_response_hop_limit = 2
      }

      # Security: Disable public IP assignment (company policy)
      subnet_ids = var.private_subnet_ids

      # Security: Enforce minimum node count (company policy)
      min_size     = max(v.min_size, var.min_node_count)
      max_size     = v.max_size
      desired_size = max(v.desired_size, var.min_node_count)

      # Security: Enable detailed monitoring
      enable_monitoring = true

      # Security: Enforce specific AMI (company policy)
      ami_type = var.ami_type

      # Security: Enforce node labels and tags
      labels = merge(
        v.labels,
        {
          "company/environment" = var.environment
          "company/managed-by"  = "terraform"
        }
      )

      tags = merge(
        v.tags,
        var.common_tags,
        {
          "company/security-policy" = "strict"
          "company/compliance"      = "required"
        }
      )
    }
  }

  # Security: Add-ons with company defaults
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi_driver[0].arn
    }
  }

  # Security: IRSA (IAM Roles for Service Accounts) configuration
  enable_irsa = true

  # Security: Cluster security group rules (company policy)
  cluster_security_group_additional_rules = {
    # Only allow internal traffic
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  # Security: Node security group rules (company policy)
  node_security_group_additional_rules = {
    # Restrict egress to company-approved destinations
    egress_https_to_company_endpoints = {
      description      = "HTTPS to company endpoints"
      protocol         = "tcp"
      from_port        = 443
      to_port          = 443
      type             = "egress"
      cidr_blocks      = var.allowed_egress_cidrs
      ipv6_cidr_blocks = []
    }
  }

  tags = merge(
    var.common_tags,
    {
      "company/security-policy" = "strict"
      "company/compliance"      = "required"
      "company/cluster-type"    = "enterprise"
    }
  )
}

# Note: KMS key is now managed by the EKS module itself

################################################################################
# EBS CSI Driver IAM Role
################################################################################

data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  count = local.create ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  count = local.create ? 1 : 0

  name               = "${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role[0].json

  tags = merge(
    var.common_tags,
    {
      Name                      = "${var.cluster_name}-ebs-csi-driver"
      "company/security-policy" = "strict"
      "company/compliance"      = "required"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count = local.create ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}

################################################################################
# Local Variables
################################################################################

locals {
  create = true
}

# Security: Additional security group for company compliance
resource "aws_security_group" "eks_compliance" {
  name        = "${var.cluster_name}-compliance"
  description = "Security group for EKS compliance requirements - ${var.cluster_name}"
  vpc_id      = var.vpc_id

  # Company policy: No ingress rules by default
  egress {
    description = "Allow all outbound traffic for compliance monitoring"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-compliance-sg"
    }
  )
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

################################################################################
# Karpenter: Removed as per repository cleanup request
################################################################################
