# Custom Modules

This directory contains custom Terraform modules that are used when official modules from [terraform-aws-modules](https://github.com/terraform-aws-modules) do not meet your organization's needs.

## Module Strategy

- **Prefer official modules** from [terraform-aws-modules](https://github.com/terraform-aws-modules) whenever available.
- Use **custom modules** here **only** when:
  - Official modules do not exist for the service (e.g., AWS MWAA)
  - Official modules do not meet your organization's needs
  - You need to enforce company-wide security policies (e.g., EKS Enterprise wrapper)
  - You need opinionated defaults or cross-service integration logic

## Custom Module Patterns

This directory demonstrates **two common patterns** for custom modules:

### Pattern 1: Custom Module (No Official Module)
**Example: MWAA**
- Use when: No official module exists
- Approach: Build from scratch using AWS provider resources
- Benefits: Full control, custom logic

### Pattern 2: Wrapper Module (Official Module Exists)
**Example: EKS Enterprise**
- Use when: Official module exists but needs company standards
- Approach: Wrap official module, add policies and validation
- Benefits: Best of both worlds - official updates + company standards

## Available Modules

### MWAA (Managed Workflows for Apache Airflow)

A custom module for AWS Managed Workflows for Apache Airflow (MWAA). This is an example of a custom module because:

- **No official module exists**: AWS MWAA doesn't have a well-maintained `terraform-aws-modules` module
- **Uncommon service**: MWAA is less commonly used than services like VPC, EKS, or RDS
- **Cross-service integration**: Requires integration with S3, IAM, CloudWatch, and VPC resources

The module creates:
- MWAA environment with configurable Airflow version
- S3 bucket for DAGs and plugins
- IAM roles and policies for MWAA execution
- CloudWatch log groups for MWAA logs
- Network configuration (security groups and subnets)

### EKS Enterprise (Wrapper Module)

A **wrapper module** around the official `terraform-aws-modules/eks/aws` module that enforces company-specific security policies and stricter defaults.

**Why a wrapper module?**
- ✅ **Enforce security policies**: Company-wide security requirements
- ✅ **Standardize configurations**: Consistent defaults across all clusters
- ✅ **Compliance requirements**: Meet regulatory or audit requirements
- ✅ **Reduce configuration errors**: Prevent misconfigurations through validation

**Company policies enforced:**
- Minimum Kubernetes version (1.28+)
- Private endpoint by default
- KMS encryption for secrets
- All control plane logging enabled
- IMDSv2 enforcement
- Disk encryption required
- Nodes in private subnets only
- Minimum node count (2)
- Log retention (30+ days)
- Instance type whitelist

This demonstrates the **wrapper pattern** - using official modules as a base while adding organizational standards on top.

