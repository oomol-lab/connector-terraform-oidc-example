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
  default     = "https://token.oomol.com"
}

variable "audience" {
  description = "Allowed OIDC audience. This value must match the token aud claim."
  type        = string
}

variable "role_name" {
  description = "IAM role name that OOMOL OIDC tokens can assume."
  type        = string
  default     = "oomol-oidc-role"
}

variable "subject_patterns" {
  description = "Allowed OIDC sub claim values or patterns. Set an empty list to skip the sub claim restriction."
  type        = list(string)
  default     = []
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
