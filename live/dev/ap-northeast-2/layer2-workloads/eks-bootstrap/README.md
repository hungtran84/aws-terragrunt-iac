# EKS Bootstrap Module

Terraform module for deploying EKS cluster bootstrap components in Layer 2.

## Components

### ✅ Implemented

- **Karpenter Configuration**: EC2NodeClass and NodePool for auto-scaling

### 🚧 Planned

- **ArgoCD**: GitOps controller for application deployment
- **AWS Load Balancer Controller**: Ingress and service load balancing
- **Metrics Server**: Resource metrics for HPA

## Prerequisites

1. **EKS Cluster** deployed with Karpenter controller enabled (`enable_karpenter = true`)
2. **Subnets and Security Groups** tagged with `karpenter.sh/discovery=<cluster-name>`
3. **IAM roles** created by EKS module for Karpenter nodes

## Usage

This module is automatically configured via Terragrunt dependency on the EKS module:

```hcl
dependency "eks" {
  config_path = "../eks"
}

inputs = {
  cluster_name                         = dependency.eks.outputs.cluster_name
  cluster_endpoint                     = dependency.eks.outputs.cluster_endpoint
  cluster_certificate_authority_data   = dependency.eks.outputs.cluster_certificate_authority_data
  karpenter_enabled                    = dependency.eks.outputs.karpenter_enabled
  karpenter_node_instance_profile_name = dependency.eks.outputs.karpenter_node_instance_profile_name
  
  enable_karpenter_config = true
  environment             = "dev"
}
```

## Deployment

### Deploy entire Layer 2 (EKS + Bootstrap)

```bash
cd live/dev/ap-northeast-2/layer2-workloads
terragrunt run-all apply
```

### Deploy Bootstrap only (after EKS exists)

```bash
cd live/dev/ap-northeast-2/layer2-workloads/eks-bootstrap
terragrunt apply
```

## Karpenter Configuration

### EC2NodeClass (default)

- **AMI**: Bottlerocket (latest)
- **Role**: `<cluster-name>-karpenter-node` (created by EKS module)
- **Subnets**: Auto-discovered via `karpenter.sh/discovery` tag
- **Security Groups**: Auto-discovered via `karpenter.sh/discovery` tag

### NodePool (default)

- **Capacity Type**: On-Demand (configurable)
- **Architecture**: AMD64
- **OS**: Linux
- **Instance Categories**: C, M, R, T (general purpose, compute, memory)
- **Instance Generation**: 3+ (modern instances)
- **Limits**: 100 vCPUs, 400Gi memory
- **Consolidation**: Enabled (1m after underutilized)

## Customization

### Change Instance Categories

```hcl
inputs = {
  # Only use compute and memory optimized instances
  karpenter_instance_categories = ["c", "m"]
}
```

### Adjust Resource Limits

```hcl
inputs = {
  karpenter_nodepool_limits = {
    cpu    = "200"
    memory = "800Gi"
  }
}
```

### Enable Spot Instances

```hcl
inputs = {
  karpenter_capacity_type = ["spot", "on-demand"]
}
```

## Verification

```bash
# Check Karpenter controller
kubectl get pods -n karpenter

# Check EC2NodeClass
kubectl get ec2nodeclass
kubectl describe ec2nodeclass default

# Check NodePool
kubectl get nodepool
kubectl describe nodepool default

# Test auto-scaling
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 5
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      containers:
      - name: inflate
        image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
        resources:
          requests:
            cpu: 1
            memory: 1Gi
EOF

# Watch nodes being provisioned
kubectl get nodes -w

# Cleanup
kubectl delete deployment inflate
```

## Troubleshooting

### Karpenter not provisioning nodes

```bash
# Check Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter --tail=100

# Verify IAM role
aws iam get-role --role-name <cluster-name>-karpenter-node

# Check subnet tags
aws ec2 describe-subnets --filters "Name=tag:karpenter.sh/discovery,Values=<cluster-name>"

# Check security group tags
aws ec2 describe-security-groups --filters "Name=tag:karpenter.sh/discovery,Values=<cluster-name>"
```

### EC2NodeClass or NodePool not created

```bash
# Check kubectl provider authentication
kubectl auth can-i get ec2nodeclass

# Verify Karpenter CRDs are installed
kubectl get crd | grep karpenter

# Check Terraform state
terragrunt state list
```

## Architecture

```
layer2-workloads/
├── eks/                      # EKS cluster + Karpenter controller
│   └── terragrunt.hcl
│
└── eks-bootstrap/            # Bootstrap components (depends on eks)
    ├── terragrunt.hcl       # Dependency configuration
    ├── main.tf              # Provider configuration
    ├── variables.tf         # Input variables
    ├── karpenter-config.tf  # EC2NodeClass + NodePool
    └── outputs.tf           # Module outputs
```

## Dependencies

```
VPC (layer1-networking/vpc)
  ↓
EKS Cluster (layer2-workloads/eks)
  ↓
EKS Bootstrap (layer2-workloads/eks-bootstrap)
```

## References

- [Karpenter Documentation](https://karpenter.sh)
- [Karpenter Best Practices](https://aws.github.io/aws-eks-best-practices/karpenter/)
- [Bottlerocket OS](https://bottlerocket.dev/)
