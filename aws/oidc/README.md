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
  -var='client_ids=["oomol"]' \
  -var='subject_patterns=["oomol:*"]'
```

Before production use, replace `subject_patterns` with the final OOMOL `sub`
claim format and verify whether you want AWS to retrieve the HTTPS thumbprint
automatically or pass an explicit `thumbprint_list`.
