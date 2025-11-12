# Layer 0 - Foundation

This layer contains bootstrap infrastructure required before anything else can be deployed.

## Components

- Terraform state S3 bucket
- DynamoDB lock table
- AWS Secrets Manager (if needed)
- ACM certificates (if needed)

## Deployment

This layer must be deployed manually first (chicken-and-egg problem). Deploy both S3 bucket and DynamoDB table:

### Deploy S3 Bucket (State Storage)

```bash
cd live/dev/ap-northeast-2/layer0-foundation/s3
terragrunt init
terragrunt plan
terragrunt apply
```

### Deploy DynamoDB Table (State Locking)

```bash
cd live/dev/ap-northeast-2/layer0-foundation/dynamodb
terragrunt init
terragrunt plan
terragrunt apply
```

### Deploy Both Together

You can deploy both resources together using `terragrunt run-all` from the layer0-foundation directory:

```bash
cd live/dev/ap-northeast-2/layer0-foundation
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

This will automatically discover and execute commands in all subdirectories (`s3/` and `dynamodb/`).

**Note**: `run-all` will process directories in dependency order if dependencies are defined. Since S3 and DynamoDB are independent, they can be deployed in any order.

**Note**: For Layer 0 Foundation, you may need to use `terraform` directly if the S3 backend doesn't exist yet. In that case:

```bash
cd live/dev/ap-northeast-2/layer0-foundation/s3
terraform init -backend=false
terraform plan
terraform apply
```

After this layer is deployed, all other layers can use the remote state backend with Terragrunt.
