# AWS OIDC example

This example creates the AWS side of an OIDC federation setup for OOMOL:

- an IAM OIDC provider for `https://token.oomol.com`
- an IAM role that trusts tokens from that provider
- trust policy conditions for `aud`, and optionally `sub`

The AWS equivalent of Alibaba Cloud OIDC is:

- `aws_iam_openid_connect_provider`
- an IAM role trust policy that allows `sts:AssumeRoleWithWebIdentity`

## Usage

Before running Terraform, update the user-specific values.

Values you must review:

| Value | Replace it? | What to use |
| --- | --- | --- |
| `audience` | Yes. | The OOMOL OIDC audience configured in `oomol-connector`. It must match the token `aud` claim. |
| `oidc_issuer_url` | No. | OOMOL's fixed issuer URL. It must match the token `iss` claim exactly. |
| `subject_patterns` | Usually yes. | OOMOL user UUIDs or patterns that match the token `sub` claim. Use an empty list to skip the `sub` restriction. |
| `thumbprint_list` | Usually no. | Leave `null` to let AWS retrieve the HTTPS thumbprint. Set it only if you need to pin explicit certificate thumbprints. |

For example, create `terraform.tfvars`:

```hcl
audience         = "replace-with-your-oomol-audience"
subject_patterns = ["replace-with-your-oomol-user-uuid"]
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

The role created here only defines who may assume it. Attach the concrete IAM
permissions OOMOL needs in your deployment before using it for real workloads.

## Reference documentation

- [AWS IAM: Create OpenID Connect identity providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [AWS STS API: AssumeRoleWithWebIdentity](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)
- [Terraform AWS provider: aws_iam_openid_connect_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider)
