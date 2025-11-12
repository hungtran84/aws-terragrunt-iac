# Layer 3 - Add-ons & Applications

This layer contains application enablement tools and app deployments on top of workloads.

## Components

- ArgoCD
- External Secrets Operator
- ALB Controller
- Cert Manager
- AppMesh
- Custom workloads deployed via GitOps (ArgoCD repo: `argo-apps`)

## Dependencies

- Layer 0 Foundation (for remote state)
- Layer 1 Networking (for VPC and subnets)
- Layer 2 Workloads (for EKS cluster)

## Deployment

```bash
cd live/dev/ap-northeast-2/layer3-apps
terragrunt run-all apply
```


