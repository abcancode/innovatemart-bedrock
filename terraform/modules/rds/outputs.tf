# terraform/modules/rds/outputs.tf

# PostgreSQL outputs
output "postgres_endpoint" {
  description = "PostgreSQL RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "postgres_port" {
  description = "PostgreSQL RDS instance port"
  value       = aws_db_instance.postgres.port
}

output "postgres_database" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.postgres.db_name
}

output "postgres_username" {
  description = "PostgreSQL username"
  value       = aws_db_instance.postgres.username
}

output "postgres_password" {
  description = "PostgreSQL password"
  value       = random_password.postgres_password.result
  sensitive   = true
}

# MySQL outputs
output "mysql_endpoint" {
  description = "MySQL RDS instance endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "mysql_port" {
  description = "MySQL RDS instance port"
  value       = aws_db_instance.mysql.port
}

output "mysql_database" {
  description = "MySQL database name"
  value       = aws_db_instance.mysql.db_name
}

output "mysql_username" {
  description = "MySQL username"
  value       = aws_db_instance.mysql.username
}

output "mysql_password" {
  description = "MySQL password"
  value       = random_password.mysql_password.result
  sensitive   = true
}

# DynamoDB outputs
output "dynamodb_table_name" {
  description = "DynamoDB table name for carts service"
  value       = aws_dynamodb_table.carts.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.carts.arn
}

# Security group output
output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

# Secrets Manager outputs
output "postgres_secret_arn" {
  description = "PostgreSQL credentials secret ARN"
  value       = aws_secretsmanager_secret.postgres_credentials.arn
}

output "mysql_secret_arn" {
  description = "MySQL credentials secret ARN"
  value       = aws_secretsmanager_secret.mysql_credentials.arn
}