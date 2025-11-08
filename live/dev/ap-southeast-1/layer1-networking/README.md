# Layer 1 - Networking

This layer contains core network and connectivity foundation.

## Components

- VPC (using official `terraform-aws-modules/vpc/aws` module)
- Subnets (public and private)
- Route tables
- NAT Gateway
- Internet Gateway
- Transit Gateway (if needed)
- PrivateLink endpoints (if needed)
- VPN (if needed)

## Dependencies

- Layer 0 Foundation (for remote state)

## Deployment

```bash
cd live/dev/ap-southeast-1/layer1-networking
terragrunt run-all apply
```

## Module Strategy

This layer uses the **official** `terraform-aws-modules/vpc/aws` module, demonstrating the preference for official modules when available. Custom modules are only used when official modules don't exist (see Layer 2 - MWAA example).

