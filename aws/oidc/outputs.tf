output "oidc_provider_arn" {
  description = "ARN of the AWS IAM OIDC provider."
  value       = aws_iam_openid_connect_provider.oomol.arn
}

output "role_arn" {
  description = "ARN of the IAM role that accepts OOMOL OIDC tokens."
  value       = aws_iam_role.oomol_oidc.arn
}

output "oidc_issuer_url" {
  description = "Issuer URL expected in the OOMOL OIDC token iss claim."
  value       = var.oidc_issuer_url
}

output "audience" {
  description = "Audience expected in the OOMOL OIDC token aud claim."
  value       = var.audience
}

output "subject_patterns" {
  description = "Subject patterns accepted for the OOMOL OIDC token sub claim."
  value       = var.subject_patterns
}
