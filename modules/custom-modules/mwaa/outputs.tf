output "mwaa_environment_arn" {
  description = "ARN of the MWAA environment"
  value       = aws_mwaa_environment.main.arn
}

output "mwaa_environment_name" {
  description = "Name of the MWAA environment"
  value       = aws_mwaa_environment.main.name
}

output "mwaa_webserver_url" {
  description = "Webserver URL of the MWAA environment"
  value       = aws_mwaa_environment.main.webserver_url
}

output "mwaa_airflow_version" {
  description = "Apache Airflow version"
  value       = aws_mwaa_environment.main.airflow_version
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for DAGs"
  value       = aws_s3_bucket.mwaa_dags.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for DAGs"
  value       = aws_s3_bucket.mwaa_dags.id
}

output "execution_role_arn" {
  description = "ARN of the IAM execution role"
  value       = aws_iam_role.mwaa.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.mwaa.name
}


