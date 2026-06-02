output "oidc_provider_arn" {
  description = "ARN of the AWS IAM OIDC provider."
  value       = aws_iam_openid_connect_provider.oomol.arn
}

output "role_arn" {
  description = "ARN of the IAM role that accepts OOMOL OIDC tokens."
  value       = aws_iam_role.oomol_oidc.arn
}

output "audience" {
  description = "Audience expected in the OOMOL OIDC token aud claim."
  value       = var.audience
}
