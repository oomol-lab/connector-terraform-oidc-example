data "google_project" "current" {
  project_id = var.project_id
}

locals {
  workload_identity_pool_provider_name = "projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${var.pool_id}/providers/${var.provider_id}"
  # For a generic audience, the default value is this Google STS audience.
  sts_audience = "//iam.googleapis.com/${local.workload_identity_pool_provider_name}"
}

resource "google_iam_workload_identity_pool" "oomol" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "OOMOL OIDC pool"
  description               = "Federation pool for OOMOL-issued OIDC tokens."
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "oomol" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.oomol.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "OOMOL OIDC provider"
  description                        = "OIDC provider for OOMOL-issued tokens."

  oidc {
    issuer_uri        = var.oidc_issuer_uri
    allowed_audiences = [var.audience]
  }

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
}

resource "google_service_account" "oomol_oidc" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
  description  = "Service account that OOMOL OIDC tokens can impersonate."
}

resource "google_service_account_iam_member" "oomol_oidc_workload_identity_user" {
  service_account_id = google_service_account.oomol_oidc.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.oomol.workload_identity_pool_id}/subject/${var.subject}"
}
