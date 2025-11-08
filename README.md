# 🧱 terragrunt-layers

> **Layered Infrastructure as Code (IaC) for AWS using Terragrunt + Terraform**

A modular, multi-account, and multi-region AWS IaC architecture built on **Terragrunt**.  
This repository defines infrastructure as **layers**, allowing clean dependency management, reusability, and safe environment promotion.

---

## 🧩 Overview

The **terragrunt-layers** approach organizes infrastructure into **layered stacks**, where each layer depends only on the layer before it.

Each environment (e.g., `dev`, `staging`, `prod`) can span **multiple regions** and **AWS accounts**, with Terragrunt managing dependencies and remote states.

```
terragrunt-layers/
├── terragrunt.hcl                  # root config (remote state, provider defaults)
├── common.hcl                      # global naming conventions and shared utilities
├── live/                           # environment-specific configurations
│   ├── dev/
│   │   ├── ap-southeast-1/
│   │   │   ├── layer0-foundation/  # S3 bucket, DynamoDB, IAM roles
│   │   │   ├── layer1-networking/  # VPC, subnets, route tables
│   │   │   │   └── vpc/
│   │   │   ├── layer2-workloads/   # EKS, RDS, ElastiCache, MWAA
│   │   │   │   ├── eks/
│   │   │   │   └── mwaa/
│   │   │   └── layer3-apps/        # ArgoCD, add-ons, applications
│   │   │       └── argocd/
│   │   └── us-east-1/
│   ├── staging/
│   └── prod/
├── modules/                        # reusable Terraform modules
│   └── custom-modules/             # custom modules (MWAA, EKS Enterprise)
│       ├── mwaa/                   # AWS Managed Workflows for Apache Airflow
│       └── eks-enterprise/         # EKS wrapper with company policies
├── docs/                           # documentation
│   ├── VERSION_MANAGEMENT.md
│   └── NAMING_CONVENTIONS.md
└── scripts/                        # utility scripts
    └── check-versions.sh
```

---

## 🪜 Layered Architecture

| Layer | Description | Example Components |
|-------|-------------|-------------------|
| **Layer 0 – Foundation** | Foundation infrastructure and shared services required before anything else. | Terraform state S3 bucket, DynamoDB lock table, AWS Accounts, IAM roles, ACM, AWS Secrets Manager |
| **Layer 1 – Networking** | Core network and connectivity foundation. | VPC, subnets, route tables, NAT gateway, Transit Gateway, PrivateLink, VPN |
| **Layer 2 – Workloads (Platform)** | Platform-level managed services and compute layer. | EKS clusters, RDS, ElastiCache (Redis), MSK, ECS, EC2 base stacks |
| **Layer 3 – Add-ons & Applications** | Application enablement layer — tools and app deployments on top of workloads. | ArgoCD, External Secrets, ALB Controller, Cert Manager, AppMesh, custom workloads deployed via GitOps (ArgoCD repo: `argo-apps`) |

---

## ⚖️ Why Layering?

While boundaries between layers can sometimes be **blurred**, the **layered model** offers significant benefits compared to a flat design:

| Benefit | Description |
|---------|-------------|
| **Clear Dependency Flow** | Layers define explicit order — e.g., networking before workloads, workloads before apps. |
| **Safe Change Management** | Each layer can be deployed independently, reducing blast radius. |
| **Reusability** | Modules can be shared or reused across environments or regions. |
| **Promotion Across Environments** | Easily promote tested infrastructure from dev → staging → prod. |
| **Flexibility** | Supports multi-account, multi-region structure without coupling everything together. |
| **Compliance & Security** | Foundation layer ensures consistent identity, logging, and encryption setup. |

---

## ⚙️ Module Strategy

- **Prefer official modules** from [terraform-aws-modules](https://github.com/terraform-aws-modules) whenever available.
- Use **custom modules** (e.g., `modules/custom-modules/`) **only** when:
  - Official modules do not meet your organization's needs.
  - You need opinionated defaults or cross-service integration logic.

Example:

```hcl
# layer2/workloads/eks/terragrunt.hcl
terraform {
  source = "terraform-aws-modules/eks/aws//modules/cluster"
  version = "20.15.0" # pinned for prod stability
}
```

---

## 🧩 Environments & Regions

Each environment is isolated but shares consistent structure:

```
live/
├── dev/
│   ├── ap-southeast-1/
│   └── us-east-1/
├── staging/
└── prod/
```

- Each region maps to a dedicated AWS account if desired.
- Terragrunt handles:
  - Remote state configuration
  - Provider alias setup
  - Cross-layer dependency references

---

## 🔐 Layer 0 Foundation

Terraform requires remote state storage (S3 + DynamoDB) to already exist — the "chicken-and-egg" problem.

✅ **Solution:**

- Manually deploy Layer 0 Foundation once (or use a lightweight script):

```bash
cd live/dev/ap-southeast-1/layer0-foundation
terragrunt init
terragrunt plan
terragrunt apply
```

**Note**: For Layer 0 Foundation, if the S3 backend doesn't exist yet, you may need to use `terraform` directly with `-backend=false`:

```bash
terraform init -backend=false
terraform plan
terraform apply
```

- After creation, all other layers use this backend for remote state.

---

## 🚀 Example Deployment Flow

1. **Deploy Layer 0 Foundation**

```bash
terragrunt run-all apply --terragrunt-include-dir layer0-foundation
```

2. **Deploy networking**

```bash
terragrunt run-all apply --terragrunt-include-dir layer1-networking
```

3. **Deploy workloads**

```bash
terragrunt run-all apply --terragrunt-include-dir layer2-workloads
```

4. **Deploy add-ons & apps**

```bash
terragrunt run-all apply --terragrunt-include-dir layer3-apps
```

---

## 🌎 Related Repositories

| Repository | Purpose |
|------------|---------|
| terragrunt-iac | Main IaC repo — defines all infra layers |
| terraform-modules | Internal reusable Terraform modules (used when no official module fits) |
| argocd-apps | GitOps repo managed by ArgoCD — deploys workloads and apps on top of EKS |
| terragrunt-layers-foundation (optional) | Minimal repo for Layer 0 Foundation setup (S3 + DynamoDB) |

---

## 🧠 Naming & Inspiration

This repo's name — **terragrunt-layers** — reflects:

- **Terragrunt-first design** — orchestration and dependency management.
- **Layered IaC model** — clear separation of foundation, platform, and application.
- **Scalable foundation** — supports multi-env, multi-account, multi-region AWS setup.

Simple, professional, and scalable — the backbone of your AWS platform.

---

## 🧰 Tech Stack

- Terraform ≥ 1.6 (see `.terraform-version`)
- Terragrunt ≥ 0.55 (see `.terragrunt-version`)
- AWS multi-account architecture (via AWS Organizations)
- ArgoCD for GitOps application management
- Optional: SSO, Security Hub, GuardDuty, CloudTrail, Config

## 📦 Version Management

This repository uses version pinning to ensure consistency. Required versions:
- **Terraform**: `1.6.0` (see `.terraform-version`)
- **Terragrunt**: `0.55.0` (see `.terragrunt-version`)

Quick check: `make check-versions` or `./scripts/check-versions.sh`

📖 **See [Version Management Guide](docs/VERSION_MANAGEMENT.md) for detailed installation instructions.**

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Version Management](docs/VERSION_MANAGEMENT.md) | How to install and manage Terraform/Terragrunt versions |
| [Naming Conventions](docs/NAMING_CONVENTIONS.md) | Resource naming standards, patterns, and quick reference |

---

## 🪶 Tagline

> "Layered. Modular. Scalable. — Infrastructure that grows with your cloud."
