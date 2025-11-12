# Karpenter Configuration Module
# Defines EC2NodeClass and NodePool for Karpenter auto-scaling

This module is part of the eks-bootstrap and requires:
- EKS cluster with Karpenter controller installed
- Subnets tagged with `karpenter.sh/discovery=<cluster-name>`
- Security groups tagged with `karpenter.sh/discovery=<cluster-name>`

## Resources Created

- **EC2NodeClass (default)**: Defines how Karpenter provisions EC2 instances
- **NodePool (default)**: Defines when and what types of nodes to provision

## Configuration

### EC2NodeClass
- AMI: Bottlerocket (latest)
- Instance Role: `<cluster-name>-karpenter-node`
- Subnets: Auto-discovered via tags
- Security Groups: Auto-discovered via tags

### NodePool
- Capacity Type: On-Demand only
- Architecture: AMD64
- Instance Families: C, M, R, T (generation 3+)
- Limits: 100 vCPUs, 400Gi memory
- Consolidation: Enabled after 1 minute
