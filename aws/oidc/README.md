# AWS OIDC example

This example creates the AWS side of an OIDC federation setup for OOMOL:

- an IAM OIDC provider for `https://api.oomol.com`
- an IAM role that trusts tokens from that provider
- trust policy conditions for `aud` and `sub`

The AWS equivalent of Alibaba Cloud OIDC is:

- `aws_iam_openid_connect_provider`
- an IAM role trust policy that allows `sts:AssumeRoleWithWebIdentity`

## Usage

```sh
terraform init
terraform plan
terraform apply
terraform output
```

Override variables as needed:

```sh
terraform plan \
  -var='aws_profile=default' \
  -var='oidc_issuer_url=https://api.oomol.com' \
  -var='client_ids=["oomol-connector-for-aws"]' \
  -var='subject_patterns=["oomol:*"]'
```

When configuring an AWS OIDC connector, use the `role_arn` output as the AWS
role to assume. Do not pass `oidc_provider_arn` to an Alibaba Cloud
`AssumeRoleWithOIDC`/`OIDCProviderArn` setting: Alibaba Cloud expects a RAM OIDC
provider ARN in the `acs:ram::...:oidc-provider/...` format, while this example
creates an AWS IAM provider ARN in the `arn:aws:iam::...:oidc-provider/...`
format.

Before production use, replace `subject_patterns` with the final OOMOL `sub`
claim format and verify whether you want AWS to retrieve the HTTPS thumbprint
automatically or pass an explicit `thumbprint_list`.

## Reference documentation

- [AWS IAM: Create OpenID Connect identity providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [AWS STS API: AssumeRoleWithWebIdentity](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)
- [Terraform AWS provider: aws_iam_openid_connect_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider)
