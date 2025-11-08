# Staging Environment Configuration

locals {
  # Environment-specific tags
  environment_tags = {
    CostCenter = "staging"
    Owner      = "platform-team"
  }
}

