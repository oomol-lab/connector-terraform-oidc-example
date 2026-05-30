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
  default     = "https://api.oomol.com"
}

variable "allowed_audiences" {
  description = "Allowed OIDC audiences. These values must match the token aud claim."
  type        = list(string)
  default     = ["oomol"]
}

variable "subject" {
  description = "OIDC sub claim allowed to impersonate the service account. Replace this with the final OOMOL subject value."
  type        = string
  default     = "oomol"
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
