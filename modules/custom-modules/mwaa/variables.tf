variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "mwaa_environment_name" {
  description = "Name of the MWAA environment"
  type        = string
  default     = ""
}

variable "airflow_version" {
  description = "Apache Airflow version"
  type        = string
  default     = "2.8.1"
}

variable "environment_class" {
  description = "Environment class (mw1.small, mw1.medium, mw1.large)"
  type        = string
  default     = "mw1.small"
}

variable "security_group_ids" {
  description = "Security group IDs for MWAA environment"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Subnet IDs for MWAA environment (must be private subnets)"
  type        = list(string)
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "log_level" {
  description = "Logging level (CRITICAL, ERROR, WARNING, INFO, DEBUG)"
  type        = string
  default     = "INFO"
}

variable "webserver_access_mode" {
  description = "Webserver access mode (PRIVATE_ONLY or PUBLIC_ONLY)"
  type        = string
  default     = "PRIVATE_ONLY"
}

variable "max_workers" {
  description = "Maximum number of workers"
  type        = number
  default     = 10
}

variable "min_workers" {
  description = "Minimum number of workers"
  type        = number
  default     = 1
}

variable "weekly_maintenance_window_start" {
  description = "Weekly maintenance window start time (e.g., SUN:03:00)"
  type        = string
  default     = "SUN:03:00"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}


