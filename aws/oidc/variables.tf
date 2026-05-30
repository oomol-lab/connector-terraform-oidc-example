variable "aws_region" {
  description = "AWS region used by the provider. IAM is global, but the AWS provider still requires a region."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional local AWS shared config profile."
  type        = string
  default     = null
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL. This must exactly match the token iss claim and AWS OIDC provider URL."
  type        = string
  default     = "https://api.oomol.com"
}

variable "client_ids" {
  description = "Allowed audiences. These values must match the token aud claim."
  type        = list(string)
  default     = ["oomol"]
}

variable "thumbprint_list" {
  description = "Optional HTTPS certificate thumbprints for the OIDC provider. Leave null to let AWS retrieve them."
  type        = list(string)
  default     = null
}

variable "role_name" {
  description = "IAM role name that OOMOL OIDC tokens can assume."
  type        = string
  default     = "oomol-oidc-role"
}

variable "subject_patterns" {
  description = "Allowed OIDC sub claim patterns. Tighten this to the final OOMOL subject format before production use."
  type        = list(string)
  default     = ["*"]
}

variable "max_session_duration" {
  description = "Maximum role session duration in seconds."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Service   = "oomol"
  }
}
