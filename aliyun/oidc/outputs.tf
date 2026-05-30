output "roleArn" {
  description = "ARN of the RAM role that accepts OOMOL OIDC tokens."
  value       = alicloud_ram_role.oomol_oidc.arn
}

output "oidcProviderArn" {
  description = "ARN of the OIDC provider used by the RAM role."
  value       = alicloud_ims_oidc_provider.oomol.arn
}
