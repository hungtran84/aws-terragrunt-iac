# EKS Enterprise Module
# Wrapper around official terraform-aws-modules/eks/aws with company-specific security policies
# and stricter defaults
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Use the official EKS module as the base
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Network configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Security: Enforce private endpoint (company policy)
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = var.allow_public_access
  cluster_endpoint_public_access_cidrs = var.allow_public_access ? var.allowed_public_cidrs : []

  # Security: Enable encryption
  cluster_enabled_log_types              = var.enabled_log_types
  create_cloudwatch_log_group           = true
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  # Security: Enable encryption at rest
  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  # Security: Enforce minimum cluster version (company policy)
  cluster_version = var.cluster_version >= "1.28" ? var.cluster_version : "1.28"

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
            kms_key_id            = aws_kms_key.eks.arn
            delete_on_termination = true
          }
        }
      }

      # Security: Enforce IMDSv2 (company security policy)
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"  # Enforce IMDSv2
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
      most_recent = true
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

# Security: KMS key for EKS encryption (company requirement)
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster encryption - ${var.cluster_name}"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-eks-key"
    }
  )
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
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


