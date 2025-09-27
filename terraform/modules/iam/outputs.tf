# terraform/modules/iam/outputs.tf

output "developer_user_name" {
  description = "Name of the developer IAM user"
  value       = aws_iam_user.developer.name
}

output "developer_user_arn" {
  description = "ARN of the developer IAM user"
  value       = aws_iam_user.developer.arn
}

output "developer_access_key_id" {
  description = "Access Key ID for the developer user"
  value       = aws_iam_access_key.developer.id
  sensitive   = true
}

output "developer_secret_access_key" {
  description = "Secret Access Key for the developer user"
  value       = aws_iam_access_key.developer.secret
  sensitive   = true
}

output "eks_readonly_policy_arn" {
  description = "ARN of the EKS read-only policy"
  value       = aws_iam_policy.eks_readonly.arn
}