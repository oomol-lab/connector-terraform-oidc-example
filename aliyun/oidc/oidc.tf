terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

locals {
  # Replace this with the OOMOL OIDC audience configured in oomol-connector.
  # It must match the token aud claim.
  audience = "replace-with-your-oomol-audience"

  # OOMOL's OIDC issuer URL. This value is fixed by OOMOL and normally should
  # not be changed. It must match the token iss claim exactly.
  oidc_issuer_url = "https://api.oomol.com"

  # Replace this with your OOMOL user UUID. Do not leave it empty: without the
  # sub check, anyone who can obtain a valid OOMOL token and knows this RAM role
  # could try to assume the role.
  oidc_subject = "replace-with-your-oomol-user-uuid"
}

data "external" "oomol_oidc_fingerprint" {
  program = [
    "${path.module}/scripts/oidc-fingerprint.sh",
    "--json",
    local.oidc_issuer_url,
  ]
}

resource "alicloud_ims_oidc_provider" "oomol" {
  client_ids = [
    local.audience,
  ]
  fingerprints = [
    data.external.oomol_oidc_fingerprint.result.fingerprint,
  ]
  issuance_limit_time = 12
  issuer_url          = local.oidc_issuer_url
  oidc_provider_name  = "oomol-oidc-provider"
}

resource "alicloud_ram_role" "oomol_oidc" {
  role_name            = "oomol-oidc-role"
  max_session_duration = 3600
  description          = "Role that accepts OOMOL OIDC tokens."

  assume_role_policy_document = jsonencode({
    Version = "1"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Federated = [
            alicloud_ims_oidc_provider.oomol.arn,
          ]
        }
        Condition = {
          StringEquals = {
            "oidc:iss" = alicloud_ims_oidc_provider.oomol.issuer_url
            "oidc:aud" = local.audience
            "oidc:sub" = local.oidc_subject
          }
        }
      },
    ]
  })
}

# This policy is intentionally minimal. It only allows sts:GetCallerIdentity,
# which OIDC-based credential retrieval tools commonly use to verify credentials.
# Update this alicloud_ram_policy policy_document with the concrete Alibaba
# Cloud permissions OOMOL should have in your deployment.
resource "alicloud_ram_policy" "oomol_oidc" {
  policy_name = "oomol-oidc-policy"
  description = "Minimal policy for credentials assumed through the OOMOL OIDC role."

  policy_document = jsonencode({
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
  })
}

resource "alicloud_ram_role_policy_attachment" "oomol_oidc" {
  policy_name = alicloud_ram_policy.oomol_oidc.policy_name
  policy_type = alicloud_ram_policy.oomol_oidc.type
  role_name   = alicloud_ram_role.oomol_oidc.role_name
}
