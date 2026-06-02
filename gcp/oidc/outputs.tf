output "workload_identity_pool_name" {
  description = "Full resource name of the Workload Identity Pool."
  value       = google_iam_workload_identity_pool.oomol.name
}

output "workload_identity_pool_provider_name" {
  description = "Full resource name of the OIDC Workload Identity Pool Provider."
  value       = google_iam_workload_identity_pool_provider.oomol.name
}

output "sts_audience" {
  description = "Audience value for Google Cloud STS token exchange."
  value       = local.sts_audience
}

output "service_account_email" {
  description = "Email of the service account that accepts OOMOL OIDC federation."
  value       = google_service_account.oomol_oidc.email
}

output "workload_identity_user_member" {
  description = "IAM principal allowed to impersonate the service account."
  value       = google_service_account_iam_member.oomol_oidc_workload_identity_user.member
}
