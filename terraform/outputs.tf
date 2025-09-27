# terraform/outputs.tf

# EKS Cluster outputs
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

# VPC outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

# Database outputs
output "postgres_endpoint" {
  description = "PostgreSQL RDS endpoint"
  value       = module.rds.postgres_endpoint
}

output "mysql_endpoint" {
  description = "MySQL RDS endpoint"
  value       = module.rds.mysql_endpoint
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.rds.dynamodb_table_name
}

# IAM outputs
output "developer_user_name" {
  description = "Name of the read-only developer IAM user"
  value       = module.iam.developer_user_name
}

output "developer_access_key_id" {
  description = "Access Key ID for developer user"
  value       = module.iam.developer_access_key_id
  sensitive   = true
}

output "developer_secret_access_key" {
  description = "Secret Access Key for developer user"
  value       = module.iam.developer_secret_access_key
  sensitive   = true
}

# Kubeconfig command
output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}