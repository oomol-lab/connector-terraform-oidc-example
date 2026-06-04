output "workload_identity_pool_provider_name" {
  description = "Full resource name of the OIDC Workload Identity Pool Provider."
  value       = google_iam_workload_identity_pool_provider.oomol.name
}

output "oidc_audience" {
  description = "OIDC token audience. Uses the Google STS audience when no custom audience is configured."
  value       = local.oidc_audience
}

output "service_accounts" {
  description = "Service accounts that accept OOMOL OIDC federation."
  value       = [google_service_account.oomol_oidc.email]
}
