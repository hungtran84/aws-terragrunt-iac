# Karpenter Bootstrap Integration - Implementation Summary

## Overview

Karpenter has been integrated into the EKS enterprise module for automatic bootstrap during EKS cluster deployment.

## Changes Made

### 1. **EKS Enterprise Module** (`modules/custom-modules/eks-enterprise/`)

#### Added Variables (variables.tf)
```hcl
- enable_karpenter (bool, default: false)
- karpenter_namespace (string, default: "karpenter")
- karpenter_chart_version (string, default: "1.1.0")
- karpenter_replicas (number, default: 2)
- karpenter_controller_resources (object)
- aws_region (string)
```

#### Added Module Integration (main.tf)
- Calls `eks-bootstrap/karpenter` module when `enable_karpenter = true`
- Auto-tags private subnets with `karpenter.sh/discovery=<cluster-name>`
- Auto-tags node security group with `karpenter.sh/discovery=<cluster-name>`
- Added provider requirements for kubernetes and helm

#### Added Outputs (outputs.tf)
- karpenter_enabled
- karpenter_controller_iam_role_arn
- karpenter_node_instance_profile_name
- karpenter_node_iam_role_arn
- karpenter_namespace

### 2. **EKS Terragrunt Configuration** (`live/dev/ap-northeast-2/layer2-workloads/eks/terragrunt.hcl`)

Added Karpenter configuration:
```hcl
enable_karpenter             = true
karpenter_namespace          = "karpenter"
karpenter_chart_version      = "1.1.0"
karpenter_replicas           = 2
karpenter_controller_resources = { ... }
```

### 3. **Layer 3 Karpenter Configuration** (`live/dev/ap-northeast-2/layer3-apps/karpenter/`)

**Refactored to only handle NodePool and EC2NodeClass:**
- terragrunt.hcl - Simplified dependencies (no longer installs Karpenter)
- ec2nodeclass.tf - Standalone Terraform with kubectl provider
- nodepool.tf - Defines default NodePool
- README.md - Updated documentation

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ layer2-workloads/eks (EKS Cluster)                     │
├─────────────────────────────────────────────────────────┤
│ • EKS Cluster                                           │
│ • Karpenter Controller (Helm Chart)                     │
│ • Karpenter IAM Roles (Controller + Node)               │
│ • Auto-tag Subnets (karpenter.sh/discovery)             │
│ • Auto-tag Security Groups (karpenter.sh/discovery)     │
└─────────────────────────────────────────────────────────┘
                          ↓ depends on
┌─────────────────────────────────────────────────────────┐
│ layer3-apps/karpenter (Configuration)                   │
├─────────────────────────────────────────────────────────┤
│ • EC2NodeClass (default)                                │
│ • NodePool (default)                                    │
└─────────────────────────────────────────────────────────┘
```

## Deployment Workflow

### Single Command Deployment

```bash
# Deploy EKS with Karpenter automatically
cd live/dev/ap-northeast-2/layer2-workloads/eks
terragrunt apply

# Then deploy Karpenter configuration
cd ../../layer3-apps/karpenter
terragrunt apply
```

### Or Use Run-All

```bash
cd live/dev/ap-northeast-2
terragrunt run-all apply \
  --terragrunt-include-dir layer1-networking/vpc \
  --terragrunt-include-dir layer2-workloads/eks \
  --terragrunt-include-dir layer3-apps/karpenter
```

## What Happens During EKS Deployment

1. **EKS Cluster Created**
2. **Karpenter Module Invoked** (if `enable_karpenter = true`)
   - Creates IAM role for Karpenter controller (IRSA)
   - Creates IAM role for Karpenter nodes
   - Creates instance profile
   - Installs Karpenter Helm chart
3. **Auto-Tagging Applied**
   - All private subnets tagged with `karpenter.sh/discovery`
   - Node security group tagged with `karpenter.sh/discovery`
4. **Ready for NodePool/EC2NodeClass** deployment

## Benefits

✅ **Single deployment** - No separate Karpenter installation step
✅ **Auto-tagging** - Subnets and SGs automatically tagged  
✅ **Consistent** - Same configuration across all environments
✅ **Maintainable** - Karpenter version managed in one place
✅ **GitOps-friendly** - Enable/disable with a single variable

## Configuration Options

### Enable Karpenter
```hcl
enable_karpenter = true
```

### High Availability
```hcl
karpenter_replicas = 3
```

### Custom Resources
```hcl
karpenter_controller_resources = {
  requests = {
    cpu    = "2"
    memory = "2Gi"
  }
  limits = {
    cpu    = "2"
    memory = "2Gi"
  }
}
```

### Different Version
```hcl
karpenter_chart_version = "1.1.1"
```

## Testing

```bash
# Verify Karpenter is running
kubectl get pods -n karpenter

# Check NodePool and EC2NodeClass
kubectl get nodepool
kubectl get ec2nodeclass

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

# Watch nodes
kubectl get nodes -w

# Cleanup
kubectl delete deployment inflate
```

## Files Modified

- ✅ `modules/custom-modules/eks-enterprise/main.tf`
- ✅ `modules/custom-modules/eks-enterprise/variables.tf`
- ✅ `modules/custom-modules/eks-enterprise/outputs.tf`
- ✅ `live/dev/ap-northeast-2/layer2-workloads/eks/terragrunt.hcl`
- ✅ `live/dev/ap-northeast-2/layer3-apps/karpenter/terragrunt.hcl`
- ✅ `live/dev/ap-northeast-2/layer3-apps/karpenter/ec2nodeclass.tf`
- ✅ `live/dev/ap-northeast-2/layer3-apps/karpenter/nodepool.tf`
- ✅ `live/dev/ap-northeast-2/layer3-apps/karpenter/README.md`

## Migration from Previous Setup

If you previously had Karpenter in layer3-apps:

1. Remove old Karpenter deployment: `terragrunt destroy` in layer3-apps/karpenter
2. Enable in EKS: Add `enable_karpenter = true` to EKS terragrunt.hcl
3. Apply EKS changes: `terragrunt apply` in layer2-workloads/eks
4. Deploy configuration: `terragrunt apply` in layer3-apps/karpenter

## Notes

- **Subnets must be tagged before Karpenter starts** - This is handled automatically
- **On-Demand instances only** - No spot instance configuration
- **Bottlerocket AMI** - Default in EC2NodeClass
- **2 replicas** - High availability by default
