output "roleArn" {
  description = "ARN of the RAM role to configure in oomol-connector."
  value       = alicloud_ram_role.oomol_oidc.arn
}

output "oidcProviderArn" {
  description = "ARN of the OIDC provider to configure in oomol-connector."
  value       = alicloud_ims_oidc_provider.oomol.arn
}

output "audience" {
  description = "Audience to configure in oomol-connector."
  value       = var.audience
}
