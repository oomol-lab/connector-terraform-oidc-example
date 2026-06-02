output "workload_identity_pool_name" {
  description = "Full resource name of the Workload Identity Pool."
  value       = google_iam_workload_identity_pool.oomol.name
}

output "workload_identity_pool_provider_name" {
  description = "Full resource name of the OIDC Workload Identity Pool Provider."
  value       = google_iam_workload_identity_pool_provider.oomol.name
}

output "oidc_audience" {
  description = "First allowed OIDC token audience configured on the Workload Identity Pool Provider."
  value       = google_iam_workload_identity_pool_provider.oomol.oidc[0].allowed_audiences[0]
}

output "service_account_email" {
  description = "Email of the service account that accepts OOMOL OIDC federation."
  value       = google_service_account.oomol_oidc.email
}

output "workload_identity_user_member" {
  description = "IAM principal allowed to impersonate the service account."
  value       = google_service_account_iam_member.oomol_oidc_workload_identity_user.member
}
