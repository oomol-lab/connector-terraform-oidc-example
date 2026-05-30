terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

locals {
  oidc_client_id  = "oomol-for-aliyun"
  oidc_issuer_url = "https://api.oomol.com"
  oidc_subject    = ""
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
    local.oidc_client_id,
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
          StringEquals = merge(
            {
              "oidc:iss" = alicloud_ims_oidc_provider.oomol.issuer_url
              "oidc:aud" = local.oidc_client_id
            },
            local.oidc_subject != "" ? {
              "oidc:sub" = local.oidc_subject
            } : {},
          )
        }
      },
    ]
  })
}

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
