# AWS Managed Workflows for Apache Airflow (MWAA) Module
# This is a custom module as there's no official terraform-aws-modules for MWAA
terraform {
  required_version = ">= 1.0"
  
  # Backend configuration - will be configured by Terragrunt
  backend "s3" {}
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 bucket for MWAA DAGs and plugins
resource "aws_s3_bucket" "mwaa_dags" {
  bucket = "${var.environment}-mwaa-dags-${var.aws_region}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-mwaa-dags"
      Purpose = "MWAA DAGs storage"
    }
  )
}

resource "aws_s3_bucket_versioning" "mwaa_dags" {
  bucket = aws_s3_bucket.mwaa_dags.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mwaa_dags" {
  bucket = aws_s3_bucket.mwaa_dags.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "mwaa_dags" {
  bucket = aws_s3_bucket.mwaa_dags.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group for MWAA
resource "aws_cloudwatch_log_group" "mwaa" {
  name              = "/aws/mwaa/${var.environment}-${var.mwaa_environment_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-mwaa-logs"
    }
  )
}

# IAM role for MWAA
resource "aws_iam_role" "mwaa" {
  name = "${var.environment}-mwaa-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "airflow.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-mwaa-execution-role"
    }
  )
}

# IAM policy for MWAA to access S3 bucket
resource "aws_iam_role_policy" "mwaa_s3" {
  name = "${var.environment}-mwaa-s3-policy"
  role = aws_iam_role.mwaa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:List*"
        ]
        Resource = [
          aws_s3_bucket.mwaa_dags.arn,
          "${aws_s3_bucket.mwaa_dags.arn}/*"
        ]
      }
    ]
  })
}

# IAM policy for MWAA CloudWatch Logs
resource "aws_iam_role_policy" "mwaa_logs" {
  name = "${var.environment}-mwaa-logs-policy"
  role = aws_iam_role.mwaa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:DescribeLogGroups"
        ]
        Resource = [
          aws_cloudwatch_log_group.mwaa.arn,
          "${aws_cloudwatch_log_group.mwaa.arn}:*"
        ]
      }
    ]
  })
}

# MWAA Environment
resource "aws_mwaa_environment" "main" {
  name         = var.mwaa_environment_name
  airflow_version = var.airflow_version
  environment_class = var.environment_class

  execution_role_arn = aws_iam_role.mwaa.arn

  source_bucket_arn = aws_s3_bucket.mwaa_dags.arn
  dag_s3_path       = "dags"

  network_configuration {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.subnet_ids
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = var.log_level
    }
    scheduler_logs {
      enabled   = true
      log_level = var.log_level
    }
    task_logs {
      enabled   = true
      log_level = var.log_level
    }
    webserver_logs {
      enabled   = true
      log_level = var.log_level
    }
    worker_logs {
      enabled   = true
      log_level = var.log_level
    }
  }

  webserver_access_mode = var.webserver_access_mode

  max_workers = var.max_workers
  min_workers = var.min_workers

  weekly_maintenance_window_start = var.weekly_maintenance_window_start

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-mwaa-environment"
    }
  )
}

data "aws_caller_identity" "current" {}


