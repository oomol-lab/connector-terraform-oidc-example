locals {
  oidc_condition_key_prefix = trimprefix(var.oidc_issuer_url, "https://")
}

resource "aws_iam_openid_connect_provider" "oomol" {
  url            = var.oidc_issuer_url
  client_id_list = [var.audience]

  tags = merge(var.tags, {
    Name = "oomol-oidc-provider"
  })
}

data "aws_iam_policy_document" "oomol_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.oomol.arn,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_condition_key_prefix}:aud"
      values   = [var.audience]
    }

    dynamic "condition" {
      for_each = length(var.subject_patterns) == 0 ? [] : [var.subject_patterns]

      content {
        test     = "StringLike"
        variable = "${local.oidc_condition_key_prefix}:sub"
        values   = condition.value
      }
    }
  }
}

resource "aws_iam_role" "oomol_oidc" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.oomol_assume_role.json
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

data "aws_iam_policy_document" "oomol_test_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "iam:GetRole",
    ]

    resources = [
      aws_iam_role.oomol_oidc.arn,
    ]
  }
}

# This policy is intentionally minimal. It only allows the assumed role to read
# its own IAM role metadata, which is enough to verify that OIDC role assumption
# returned credentials with usable AWS API permissions. Replace policy_document
# with the concrete AWS permissions OOMOL should have in your deployment.
resource "aws_iam_role_policy" "oomol_oidc" {
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.oomol_oidc.id
  policy = var.policy_document == null ? data.aws_iam_policy_document.oomol_test_permissions.json : jsonencode(var.policy_document)
}
