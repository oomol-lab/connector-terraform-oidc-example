[中文说明](#阿里云-oidc-示例)

# Alibaba Cloud OIDC example

This example creates the Alibaba Cloud side of an OIDC federation setup for
OOMOL.

It creates:

- an IMS OIDC provider for `https://api.oomol.com`
- a RAM role that trusts tokens from that provider
- trust policy conditions for `iss`, `aud`, and `sub`
- a minimal RAM policy that allows `sts:GetCallerIdentity`

## Usage

Before running Terraform, update the user-specific values in `oidc.tf`.

Values you must review:

| Value | Replace it? | What to use |
| --- | --- | --- |
| `oidc_client_id` | Yes. | Your OOMOL OIDC client ID. Configure the same value in `oomol-connector`. It must match the token `aud` claim. |
| `oidc_issuer_url` | No. | OOMOL's fixed issuer URL. It must match the token `iss` claim exactly. |
| `oidc_subject` | Yes. | Your OOMOL user UUID. It must match the token `sub` claim. |

The Terraform file marks the same values in the `locals` block:

```hcl
locals {
  oidc_client_id  = "replace-with-your-oomol-client-id"
  oidc_issuer_url = "https://api.oomol.com"
  oidc_subject    = "replace-with-your-oomol-user-uuid"
}
```

Do not leave `oidc_subject` empty. The RAM role must check the token `sub`
claim, otherwise anyone who can obtain a valid OOMOL token and knows this role
could try to assume it.

The included `alicloud_ram_policy` is intentionally minimal. It only allows
`sts:GetCallerIdentity`, which is enough to verify that OIDC role assumption
works. Update the `policy_document` with the concrete Alibaba Cloud permissions
OOMOL needs in your deployment.

Then run:

```sh
terraform init
terraform plan
terraform apply
```

After apply, put the `roleArn` and `oidcProviderArn` outputs into
`oomol-connector` to finish the OIDC integration.

```sh
terraform output roleArn
terraform output oidcProviderArn
```

The provider defaults to `cn-hangzhou`. Override `alicloud_region` and
`alicloud_profile` if you need a different region or local CLI profile.

# 阿里云 OIDC 示例

这个示例用于创建 OOMOL OIDC 联邦登录所需的阿里云侧资源。

创建内容包括：

- 指向 `https://api.oomol.com` 的 IMS OIDC Provider
- 信任该 OIDC Provider token 的 RAM Role
- 针对 `iss`、`aud` 和 `sub` 的信任策略条件
- 一个只允许 `sts:GetCallerIdentity` 的最小 RAM Policy

## 使用方式

运行 Terraform 前，先修改 `oidc.tf` 里和用户环境相关的值。

需要重点检查的值：

| 值 | 是否需要替换 | 应该填什么 |
| --- | --- | --- |
| `oidc_client_id` | 需要替换。 | 你的 OOMOL OIDC client ID，并在 `oomol-connector` 里配置同一个值。它必须匹配 token 的 `aud` claim。 |
| `oidc_issuer_url` | 不需要替换。 | OOMOL 固定的 issuer URL，必须和 token 的 `iss` claim 完全一致。 |
| `oidc_subject` | 需要替换。 | 你的 OOMOL 用户 UUID，必须匹配 token 的 `sub` claim。 |

Terraform 文件里同样在 `locals` 配置块标出了这些值：

```hcl
locals {
  oidc_client_id  = "replace-with-your-oomol-client-id"
  oidc_issuer_url = "https://api.oomol.com"
  oidc_subject    = "replace-with-your-oomol-user-uuid"
}
```

不要让 `oidc_subject` 保持为空。RAM Role 必须校验 token 的 `sub` claim；否则只要
有人能拿到有效的 OOMOL token，并且知道这个 role，就可能尝试伪造 AssumeRole。

示例里的 `alicloud_ram_policy` 刻意保持最小权限，只允许
`sts:GetCallerIdentity`，用于验证 OIDC AssumeRole 是否成功。实际部署时，需要根据
你的使用场景填写 `policy_document`，授予 OOMOL 需要执行的具体阿里云权限。

然后执行：

```sh
terraform init
terraform plan
terraform apply
```

`apply` 完成后，把 `roleArn` 和 `oidcProviderArn` 输出值填到 `oomol-connector` 里，
完成 OIDC 对接。

```sh
terraform output roleArn
terraform output oidcProviderArn
```

provider 默认使用 `cn-hangzhou` 区域。如果需要其他区域或本地 CLI profile，请覆盖
`alicloud_region` 和 `alicloud_profile`。
