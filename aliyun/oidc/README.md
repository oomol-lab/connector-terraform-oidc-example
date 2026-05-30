# Alibaba Cloud OIDC example / 阿里云 OIDC 示例

This example creates the Alibaba Cloud side of an OIDC federation setup for
OOMOL.

这个示例用于创建 OOMOL OIDC 联邦登录所需的阿里云侧资源。

It creates:

创建内容包括：

- an IMS OIDC provider for `https://api.oomol.com`
- a RAM role that trusts tokens from that provider
- trust policy conditions for `iss`, `aud`, and optionally `sub`
- a minimal RAM policy that allows `sts:GetCallerIdentity`
- 指向 `https://api.oomol.com` 的 IMS OIDC Provider
- 信任该 OIDC Provider token 的 RAM Role
- 针对 `iss`、`aud` 以及可选 `sub` 的信任策略条件
- 一个只允许 `sts:GetCallerIdentity` 的最小 RAM Policy

## Usage / 使用方式

Before running Terraform, fill in the `locals` block in `oidc.tf`.

运行 Terraform 前，先填写 `oidc.tf` 里的 `locals` 配置。

```hcl
locals {
  oidc_client_id  = "oomol-for-aliyun"
  oidc_issuer_url = "https://api.oomol.com"
  oidc_subject    = "replace-with-final-oomol-sub"
}
```

Keep these values aligned with the OOMOL OIDC token.

这些值需要和 OOMOL OIDC token 中的 claim 保持一致。

- `oidc_client_id` must match the token `aud` claim.
- `oidc_issuer_url` must match the token `iss` claim exactly.
- `oidc_subject` should match the token `sub` claim. Leave it empty only for a
  broad test role; fill it before production use.
- `oidc_client_id` 必须匹配 token 的 `aud` claim。
- `oidc_issuer_url` 必须和 token 的 `iss` claim 完全一致。
- `oidc_subject` 应该匹配 token 的 `sub` claim。只有在临时测试较宽松角色时才留空；
  生产使用前需要填上。

Then run:

然后执行：

```sh
terraform init
terraform plan
terraform apply
```

After apply, use the outputs to finish the OIDC integration on the OOMOL side.

`apply` 完成后，使用输出值回填到 OOMOL 侧，完成 OIDC 对接。

```sh
terraform output roleArn
terraform output oidcProviderArn
```

The provider defaults to `cn-hangzhou`. Override `alicloud_region` and
`alicloud_profile` if you need a different region or local CLI profile.

provider 默认使用 `cn-hangzhou` 区域。如果需要其他区域或本地 CLI profile，请覆盖
`alicloud_region` 和 `alicloud_profile`。
