# AWS OIDC example

This example creates the AWS side of an OIDC federation setup for OOMOL:

- an IAM OIDC provider for `https://token.oomol.com`
- an IAM role that trusts tokens from that provider
- trust policy conditions for `aud`, and optionally `sub`
- a minimal inline IAM policy that allows `iam:GetRole` on the created role

The AWS equivalent of Alibaba Cloud OIDC is:

- `aws_iam_openid_connect_provider`
- an IAM role trust policy that allows `sts:AssumeRoleWithWebIdentity`
- an IAM identity policy attached to the role for the permissions OOMOL should use

## Usage

Before running Terraform, update the user-specific values.

This directory already includes a `terraform.tfvars.example` template. Rename
it to `terraform.tfvars` and edit the values you need. Terraform loads
`terraform.tfvars` from the current working directory automatically, so the
variables in that file take effect for `terraform plan` and `terraform apply`
without extra `-var` flags.

Values you must review:

| Value | Replace it? | What to use |
| --- | --- | --- |
| `audience` | Yes. | The OOMOL OIDC audience configured in `oomol-connector`. It must match the token `aud` claim. |
| `oidc_issuer_url` | No. | OOMOL's fixed issuer URL. It must match the token `iss` claim exactly. |
| `subject_patterns` | Usually yes. | OOMOL user UUIDs or patterns that match the token `sub` claim. Use an empty list to skip the `sub` restriction. |
| `policy_document` | Usually. | The concrete AWS permissions OOMOL needs in your deployment. Leave it unset to use the minimal `iam:GetRole` test policy. |

The included `terraform.tfvars.example` looks like this after you rename it to
`terraform.tfvars` and fill in your values:

```hcl
audience         = "replace-with-your-oomol-audience"
subject_patterns = ["replace-with-your-oomol-user-uuid"]

policy_document = {
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = [
        "iam:GetRole",
      ]
      Resource = [
        "arn:aws:iam::<ACCOUNT_ID>:role/oomol-oidc-role",
      ]
    },
  ]
}
```

Then run:

```sh
terraform init
terraform plan
terraform apply
```

Override AWS environment values as needed:

```sh
terraform plan \
  -var='aws_profile=default' \
  -var='aws_region=us-east-1'
```

Do not leave `subject_patterns` as `["*"]` or any other broad wildcard in
production. If `subject_patterns` is empty, Terraform will omit the `sub`
condition entirely, so anyone who can obtain a valid OOMOL token for the
configured audience and knows this role could try to assume it.

The included inline role policy is intentionally minimal. It only allows
`iam:GetRole` on the role created by this example, which is enough to verify
that OIDC role assumption returned credentials with usable AWS API permissions.
After assuming the role, verify the test permission with:

```sh
aws iam get-role --role-name oomol-oidc-role
```

Override `policy_document` with the concrete AWS permissions OOMOL needs for
real workloads.

After apply, put the `role_arn` output into `oomol-connector` to finish the OIDC
integration.

Field mapping:

| Terraform value or output | `oomol-connector` field |
| --- | --- |
| `audience` | AWS OIDC `audience` |
| `role_arn` | AWS Role ARN to assume |

```sh
terraform output role_arn
```

## Reference documentation

- [AWS IAM: Create OpenID Connect identity providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [AWS STS API: AssumeRoleWithWebIdentity](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)
- [Terraform AWS provider: aws_iam_openid_connect_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider)
- [Terraform AWS provider: aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)
