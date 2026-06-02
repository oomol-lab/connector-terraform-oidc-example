variable "alicloud_region" {
  description = "Alibaba Cloud region used by the provider."
  type        = string
  default     = "cn-hangzhou"
}

variable "alicloud_profile" {
  description = "Optional local Alibaba Cloud CLI profile."
  type        = string
  default     = null
}

variable "audience" {
  description = "Allowed OIDC audience. This value must match the token aud claim."
  type        = string
}

variable "oidc_subject" {
  description = "OOMOL user UUID from the OIDC sub claim allowed to assume the RAM role."
  type        = string
}

variable "policy_document" {
  description = "RAM policy document attached to the OOMOL OIDC role. Replace this with the concrete Alibaba Cloud permissions OOMOL needs."
  type        = any
  default = {
    Version = "1"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity",
        ]
        Resource = [
          "*",
        ]
      },
    ]
  }
}
