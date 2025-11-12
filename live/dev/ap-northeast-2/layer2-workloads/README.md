# Layer 2 - Workloads (Platform)

This layer contains platform-level managed services and compute layer.

## Components

- EKS clusters (using **enterprise wrapper module** - enforces company security policies)
- MWAA - Managed Workflows for Apache Airflow (using **custom module** - no official module exists)
- RDS databases
- ElastiCache (Redis)
- MSK (Kafka)
- ECS clusters
- EC2 base stacks

## Dependencies

- Layer 0 Foundation (for remote state)
- Layer 1 Networking (for VPC and subnets)

## Deployment

```bash
cd live/dev/ap-northeast-2/layer2-workloads
terragrunt run-all apply
```

## Custom Module Examples

### MWAA (No Official Module)

This layer includes an example of a **custom module** (MWAA) because:

- AWS MWAA doesn't have an official `terraform-aws-modules` module
- It's an uncommon service that requires custom configuration
- It demonstrates when custom modules are necessary vs. using official modules

See `modules/custom-modules/mwaa/` for the custom module implementation.

### EKS Enterprise (Wrapper Module)

This layer uses an **enterprise wrapper module** for EKS that:

- Wraps the official `terraform-aws-modules/eks/aws` module
- Enforces company-wide security policies automatically
- Standardizes configurations across all clusters
- Adds company-specific resources (KMS keys, compliance security groups)

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

See `modules/custom-modules/eks-enterprise/` for the wrapper module implementation.

This demonstrates the **wrapper pattern** - using official modules as a base while adding organizational standards on top.
