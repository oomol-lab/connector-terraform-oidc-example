variable "project_id" {
  description = "Google Cloud project ID that owns the workload identity pool and service account."
  type        = string
}

variable "pool_id" {
  description = "Workload Identity Pool ID for OOMOL-issued OIDC tokens."
  type        = string
  default     = "oomol-oidc-pool"
}

variable "provider_id" {
  description = "Workload Identity Pool Provider ID for the OOMOL OIDC issuer."
  type        = string
  default     = "oomol-oidc-provider"
}

variable "oidc_issuer_uri" {
  description = "OIDC issuer URI. This must exactly match the token iss claim."
  type        = string
  default     = "https://token.oomol.com"
}

variable "audience" {
  description = "Allowed OIDC token audience. This must match the token aud claim."
  type        = string
  default     = "replace-with-your-oomol-audience"
}

variable "subject" {
  description = "OOMOL user UUID from the OIDC sub claim allowed to impersonate the service account."
  type        = string
  default     = "replace-with-your-oomol-user-uuid"
}

variable "service_account_id" {
  description = "Service account ID that OOMOL OIDC tokens can impersonate."
  type        = string
  default     = "oomol-oidc-sa"
}

variable "service_account_display_name" {
  description = "Display name for the service account."
  type        = string
  default     = "OOMOL OIDC service account"
}

variable "test_role_id" {
  description = "Project custom role ID for the minimal OOMOL OIDC test permission role."
  type        = string
  default     = "oomol_oidc_project_viewer"
}

variable "test_role_permissions" {
  description = "Permissions granted to the OOMOL OIDC service account for testing. Replace these with the concrete Google Cloud permissions OOMOL needs."
  type        = list(string)
  default = [
    "resourcemanager.projects.get",
  ]
}
