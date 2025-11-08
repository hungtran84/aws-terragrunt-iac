# Production Environment Configuration

locals {
  # Environment-specific tags
  environment_tags = {
    CostCenter = "production"
    Owner      = "platform-team"
    Backup     = "required"
  }
}

