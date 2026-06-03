[中文说明](#阿里云-oidc-示例)

# Alibaba Cloud OIDC example

This example creates the Alibaba Cloud side of an OIDC federation setup for
OOMOL.

It creates:

- an IMS OIDC provider for `https://token.oomol.com`
- a RAM role that trusts tokens from that provider
- trust policy conditions for `iss`, `aud`, and optionally `sub`
- a minimal RAM policy that allows `sts:GetCallerIdentity`

## Usage

Before running Terraform, set the user-specific variables in `terraform.tfvars`
or pass them with `-var`.

Values you must review:

| Value | Replace it? | What to use |
| --- | --- | --- |
| `audience` | Yes. | The OOMOL OIDC audience configured in `oomol-connector`. It must match the token `aud` claim. |
| `https://token.oomol.com` | No. | OOMOL's fixed issuer URL. It must match the token `iss` claim exactly. |
| `oidc_subject` | Yes. | Your OOMOL user UUID. When non-empty, it must match the token `sub` claim. Set it explicitly to `""` to omit the `sub` condition. |
| `policy_document` | Usually. | The concrete Alibaba Cloud permissions OOMOL needs in your deployment. |

Alibaba Cloud Terraform supports selecting a local Alibaba Cloud CLI profile:

```hcl
provider "alicloud" {
  region  = "cn-hangzhou"
  profile = "customprofile"
}
```

Create or select the profile with Alibaba Cloud CLI:

```sh
aliyun configure --profile customprofile --mode AK
aliyun configure switch --profile customprofile
```

The RAM user or role behind this profile must be allowed to manage the RAM and
IMS resources created by this example. For a scoped profile, attach a policy
like this:

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ims:CreateOIDCProvider",
        "ims:GetOIDCProvider",
        "ims:UpdateOIDCProvider",
        "ims:DeleteOIDCProvider",
        "ram:CreateRole",
        "ram:GetRole",
        "ram:UpdateRole",
        "ram:DeleteRole",
        "ram:CreatePolicy",
        "ram:GetPolicy",
        "ram:ListPolicyVersions",
        "ram:GetPolicyVersion",
        "ram:DeletePolicy",
        "ram:AttachPolicyToRole",
        "ram:DetachPolicyFromRole",
        "ram:ListPoliciesForRole"
      ],
      "Resource": "*"
    }
  ]
}
```

You can also use Alibaba Cloud's online Terraform platform instead of running
Terraform locally:

<https://api.aliyun.com/terraform?source=ResourceType&activeTab=code&providerVersion=1.279.0&sourcePath=VPC%2Falicloud_vpc>

Paste this example's Terraform code into the online editor and run it with your
Alibaba Cloud account there. In that flow, Alibaba Cloud handles the execution
environment and account authentication, so you do not need a local CLI profile
for the run.

Example `terraform.tfvars`:

```hcl
alicloud_profile = "customprofile"
audience         = "replace-with-your-oomol-audience"
oidc_subject     = "replace-with-your-oomol-user-uuid"

policy_document = {
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
```

For stricter trust policy matching, set `oidc_subject` to your OOMOL user UUID
so the RAM role checks the token `sub` claim. If you explicitly set
`oidc_subject = ""`, Terraform omits the `oidc:sub` condition from the role
assume policy.

The included `alicloud_ram_policy` is intentionally minimal. It only allows
`sts:GetCallerIdentity`, which is enough to verify that OIDC role assumption
works. Override the `policy_document` variable with the concrete Alibaba Cloud permissions
OOMOL needs in your deployment.

Then run:

```sh
terraform init
terraform plan
terraform apply
```

After apply, put the `roleArn` and `oidcProviderArn` outputs into
`oomol-connector` to finish the OIDC integration.

Field mapping:

| Terraform value or output | `oomol-connector` field |
| --- | --- |
| `audience` | Alibaba Cloud STS `audience` |
| `oidcProviderArn` | Alibaba Cloud STS `OIDC Provider ARN` |
| `roleArn` | `RoleARN` |

```sh
terraform output audience
terraform output roleArn
terraform output oidcProviderArn
```

The provider defaults to `cn-hangzhou`. Override `alicloud_region` and
`alicloud_profile` if you need a different region or local CLI profile.

## Reference documentation

- [Alibaba Cloud CLI: configure credentials](https://www.alibabacloud.com/help/doc-detail/121193.html)
- [Alibaba Cloud Terraform Provider](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs)
- [Alibaba Cloud RAM: OIDC role-based SSO overview](https://www.alibabacloud.com/help/en/ram/overview-of-oidc-based-sso)
- [Alibaba Cloud RAM API: AssumeRoleWithOIDC](https://www.alibabacloud.com/help/en/doc-detail/371866.html)

# 阿里云 OIDC 示例

这个示例用于创建 OOMOL OIDC 联邦登录所需的阿里云侧资源。

创建内容包括：

- 指向 `https://token.oomol.com` 的 IMS OIDC Provider
- 信任该 OIDC Provider token 的 RAM Role
- 针对 `iss`、`aud` 以及可选 `sub` 的信任策略条件
- 一个只允许 `sts:GetCallerIdentity` 的最小 RAM Policy

## 使用方式

运行 Terraform 前，先在 `terraform.tfvars` 里设置和用户环境相关的变量，或者通过
`-var` 传入。

需要重点检查的值：

| 值 | 是否需要替换 | 应该填什么 |
| --- | --- | --- |
| `audience` | 需要替换。 | `oomol-connector` 里配置的 OOMOL OIDC audience。它必须匹配 token 的 `aud` claim。 |
| `https://token.oomol.com` | 不需要替换。 | OOMOL 固定的 issuer URL，必须和 token 的 `iss` claim 完全一致。 |
| `oidc_subject` | 需要替换。 | 你的 OOMOL 用户 UUID；非空时必须匹配 token 的 `sub` claim。显式设为 `""` 时不写入 `sub` 条件。 |
| `policy_document` | 通常需要替换。 | OOMOL 在你的部署里需要的具体阿里云权限。 |

阿里云 Terraform 支持指定本地 Alibaba Cloud CLI profile：

```hcl
provider "alicloud" {
  region  = "cn-hangzhou"
  profile = "customprofile"
}
```

可以先用阿里云 CLI 创建或切换 profile：

```sh
aliyun configure --profile customprofile --mode AK
aliyun configure switch --profile customprofile
```

这个 profile 背后的 RAM 用户或角色需要有权限管理本示例创建的 RAM 和 IMS 资源。
如果要给它配置一份收窄权限，可以附加类似下面的 RAM Policy：

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ims:CreateOIDCProvider",
        "ims:GetOIDCProvider",
        "ims:UpdateOIDCProvider",
        "ims:DeleteOIDCProvider",
        "ram:CreateRole",
        "ram:GetRole",
        "ram:UpdateRole",
        "ram:DeleteRole",
        "ram:CreatePolicy",
        "ram:GetPolicy",
        "ram:ListPolicyVersions",
        "ram:GetPolicyVersion",
        "ram:DeletePolicy",
        "ram:AttachPolicyToRole",
        "ram:DetachPolicyFromRole",
        "ram:ListPoliciesForRole"
      ],
      "Resource": "*"
    }
  ]
}
```

也可以不在本地运行 Terraform，改用阿里云 Terraform 在线平台：

<https://api.aliyun.com/terraform?source=ResourceType&activeTab=code&providerVersion=1.279.0&sourcePath=VPC%2Falicloud_vpc>

把本示例里的 Terraform 代码贴到在线编辑器中，并在阿里云账号环境里执行。这个流程由
阿里云提供执行环境和账号认证，因此运行时不需要配置本地 CLI profile。

示例 `terraform.tfvars`：

```hcl
alicloud_profile = "customprofile"
audience         = "replace-with-your-oomol-audience"
oidc_subject     = "replace-with-your-oomol-user-uuid"

policy_document = {
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
```

为了更严格地限制信任策略，建议把 `oidc_subject` 设为你的 OOMOL 用户 UUID，让
RAM Role 校验 token 的 `sub` claim。如果显式设置 `oidc_subject = ""`，Terraform
会从 role assume policy 里省略 `oidc:sub` 条件。

示例里的 `alicloud_ram_policy` 刻意保持最小权限，只允许
`sts:GetCallerIdentity`，用于验证 OIDC AssumeRole 是否成功。实际部署时，需要根据
你的使用场景覆盖 `policy_document` 变量，授予 OOMOL 需要执行的具体阿里云权限。

然后执行：

```sh
terraform init
terraform plan
terraform apply
```

`apply` 完成后，把 `roleArn` 和 `oidcProviderArn` 输出值填到 `oomol-connector` 里，
完成 OIDC 对接。

字段映射：

| Terraform 值或输出 | `oomol-connector` 字段 |
| --- | --- |
| `audience` | Aliyun Cloud STS 的 `audience` |
| `oidcProviderArn` | Aliyun Cloud STS 的 `OIDC Provider ARN` |
| `roleArn` | `RoleARN` |

```sh
terraform output audience
terraform output roleArn
terraform output oidcProviderArn
```

provider 默认使用 `cn-hangzhou` 区域。如果需要其他区域或本地 CLI profile，请覆盖
`alicloud_region` 和 `alicloud_profile`。

## 参考文档

- [阿里云 CLI：配置凭证](https://www.alibabacloud.com/help/doc-detail/121193.html)
- [阿里云 Terraform Provider](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs)
- [阿里云 RAM：OIDC 角色 SSO 概览](https://www.alibabacloud.com/help/en/ram/overview-of-oidc-based-sso)
- [阿里云 RAM API：AssumeRoleWithOIDC](https://www.alibabacloud.com/help/en/doc-detail/371866.html)
