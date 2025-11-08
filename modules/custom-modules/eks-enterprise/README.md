# EKS Enterprise Module

A **wrapper module** around the official `terraform-aws-modules/eks/aws` module that enforces company-specific security policies and stricter defaults.

## Why This Custom Module?

This module demonstrates a common enterprise pattern: **wrapping official modules** to enforce organizational standards, even when official modules exist.

### Use Cases

- ✅ **Enforce security policies**: Company-wide security requirements
- ✅ **Standardize configurations**: Consistent defaults across all clusters
- ✅ **Compliance requirements**: Meet regulatory or audit requirements
- ✅ **Reduce configuration errors**: Prevent misconfigurations through validation
- ✅ **Add company-specific resources**: Additional security groups, KMS keys, etc.

## Company Security Policies Enforced

| Policy | Description | Default |
|--------|-------------|---------|
| **Minimum Kubernetes Version** | Enforce minimum cluster version | 1.28+ |
| **Private Endpoint** | Cluster endpoint is private by default | `true` |
| **Encryption at Rest** | KMS encryption for secrets | Required |
| **Control Plane Logging** | All log types enabled | All enabled |
| **IMDSv2** | Enforce IMDSv2 on nodes | Required |
| **Disk Encryption** | EBS volumes encrypted | Required |
| **Private Subnets** | Nodes must be in private subnets | Required |
| **Minimum Node Count** | Minimum nodes per group | 2 |
| **Log Retention** | CloudWatch log retention | 30+ days |
| **Instance Type Validation** | Only allow approved instance types | Whitelist |

## Usage

```hcl
module "eks_enterprise" {
  source = "../../modules/custom-modules/eks-enterprise"
  
  cluster_name    = "prod-eks-cluster"
  cluster_version = "1.28"
  environment     = "prod"
  
  vpc_id             = "vpc-xxxxxxxxx"
  subnet_ids         = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
  private_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
  
  # Company policy: Public access disabled by default
  allow_public_access = false
  
  # Node groups with company standards
  node_groups = {
    main = {
      instance_types = ["t3.large", "t3.xlarge"]
      disk_size      = 50
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      ami_type       = "AL2_x86_64"
      labels = {
        "node-type" = "general"
      }
      tags = {}
    }
  }
  
  common_tags = {
    Environment = "prod"
    CostCenter  = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the EKS cluster | string | - | yes |
| cluster_version | Kubernetes version (min 1.28) | string | "1.28" | no |
| environment | Environment name | string | - | yes |
| vpc_id | VPC ID | string | - | yes |
| subnet_ids | Subnet IDs for cluster | list(string) | - | yes |
| private_subnet_ids | Private subnet IDs for nodes | list(string) | - | yes |
| node_groups | Map of node group definitions | map(object) | {} | no |
| allow_public_access | Allow public endpoint access | bool | false | no |
| allowed_public_cidrs | CIDR blocks for public access | list(string) | [] | no |
| allowed_instance_types | Allowed instance types | list(string) | See defaults | no |
| min_node_count | Minimum nodes per group | number | 2 | no |
| ami_type | AMI type (AL2 enforced) | string | "AL2_x86_64" | no |
| log_retention_days | CloudWatch log retention | number | 30 | no |
| common_tags | Common tags | map(string) | {} | no |

## Outputs

All outputs from the official EKS module are re-exported, plus:

- `kms_key_id` - KMS key ID for encryption
- `kms_key_arn` - KMS key ARN
- `compliance_security_group_id` - Additional compliance security group

## Module Pattern

This module follows the **wrapper pattern**:

```
┌─────────────────────────────────────┐
│  EKS Enterprise Module (Custom)     │
│  - Company security policies         │
│  - Stricter defaults                │
│  - Additional resources             │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Official terraform-aws-modules    │
│  /eks/aws module                    │
│  - Core EKS functionality           │
└─────────────────────────────────────┘
```

## Benefits

1. **Security by Default**: All company security policies enforced automatically
2. **Consistency**: Same configuration across all clusters
3. **Compliance**: Meets audit and regulatory requirements
4. **Maintainability**: Update policies in one place
5. **Best of Both Worlds**: Official module updates + company standards

## When to Use This Pattern

✅ **Use wrapper modules when:**
- You need to enforce company-wide security policies
- You want to standardize configurations across teams
- You need to add company-specific resources
- You want to prevent common misconfigurations

❌ **Don't use wrapper modules when:**
- Official module already meets all requirements
- You only need minor customizations (use variables instead)
- You're duplicating official module code unnecessarily


