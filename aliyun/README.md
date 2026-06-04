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

Before running Terraform, install and configure Alibaba Cloud CLI, and then
update the user-specific values in `oidc.tf`.

This directory already includes a `terraform.tfvars.example` template. Rename
it to `terraform.tfvars` and update the values you need. Terraform loads
`terraform.tfvars` from the current working directory automatically, so the
variables in that file take effect for `terraform plan` and `terraform apply`
without extra `-var` flags.

### 1. Install and configure Alibaba Cloud CLI

On macOS, you can install the CLI with Homebrew:

```sh
brew install aliyun-cli
aliyun version
```

Then create a local profile. Interactive mode is the simplest option:

```sh
aliyun configure --profile my-aliyun
```

If you prefer a non-interactive setup, you can create the same profile with an
AccessKey pair:

```sh
aliyun configure set \
  --profile my-aliyun \
  --mode AK \
  --access-key-id <your-access-key-id> \
  --access-key-secret <your-access-key-secret> \
  --region cn-hangzhou
```

Use a RAM user or another least-privilege credential source instead of an
account root AccessKey. Alibaba Cloud CLI stores profiles in
`~/.aliyun/config.json` on macOS and Linux.

### 2. How the Terraform provider is configured in this example

This example does not hardcode credentials in Terraform. The provider only sets
the region and CLI profile name:

```hcl
provider "alicloud" {
  region  = var.alicloud_region
  profile = var.alicloud_profile
}
```

That means:

- `alicloud_region` controls the provider region and defaults to `cn-hangzhou`.
- `alicloud_profile` selects a profile from your local Alibaba Cloud CLI
  configuration.
- If you want deterministic behavior on a machine with multiple profiles,
  explicitly pass `alicloud_profile` instead of relying on whatever local
  default profile happens to be active.

For example:

```sh
terraform plan \
  -var alicloud_region=cn-hangzhou \
  -var alicloud_profile=my-aliyun
```

You can also set them once per shell session:

```sh
export TF_VAR_alicloud_region=cn-hangzhou
export TF_VAR_alicloud_profile=my-aliyun
```

### 3. Switch profiles

If you want to change the active profile used by the Alibaba Cloud CLI itself,
run:

```sh
aliyun configure switch --profile my-aliyun
```

If you want Terraform in this example to use a specific profile, the most
explicit way is to pass it on each command:

```sh
terraform plan -var alicloud_profile=my-aliyun
terraform apply -var alicloud_profile=my-aliyun
terraform destroy -var alicloud_profile=my-aliyun
```

Using `TF_VAR_alicloud_profile` is also fine if you want to avoid repeating the
same flag across multiple Terraform commands.

### 4. Update the OIDC values in `oidc.tf`

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

The included `terraform.tfvars.example` looks like this after you rename it to
`terraform.tfvars` and fill in your values:

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

### 5. Run Terraform

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
- [Alibaba Cloud CLI: Configure credentials](https://www.alibabacloud.com/help/en/cli/configure-alibaba-cloud-cli/configure-credentials)
- [Terraform Registry: Alibaba Cloud provider authentication](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs)

# 阿里云 OIDC 示例

这个示例用于创建 OOMOL OIDC 联邦登录所需的阿里云侧资源。

创建内容包括：

- 指向 `https://token.oomol.com` 的 IMS OIDC Provider
- 信任该 OIDC Provider token 的 RAM Role
- 针对 `iss`、`aud` 以及可选 `sub` 的信任策略条件
- 一个只允许 `sts:GetCallerIdentity` 的最小 RAM Policy

## 使用方式

运行 Terraform 前，先安装并配置阿里云 CLI，再修改 `oidc.tf` 里和用户环境相关的值。

这个目录已经自带 `terraform.tfvars.example` 模板。把它改名为
`terraform.tfvars` 后，再把里面的值改成你自己的即可。Terraform 会自动加载当前目
录下的 `terraform.tfvars`，所以文件里的变量会在 `terraform plan` 和
`terraform apply` 时直接生效，不需要额外再写 `-var`。

### 1. 安装并配置阿里云 CLI

在 macOS 上，可以直接用 Homebrew 安装：

```sh
brew install aliyun-cli
aliyun version
```

安装完成后，先创建一个本地 profile。最简单的是交互式配置：

```sh
aliyun configure --profile my-aliyun
```

如果你更想用非交互方式，也可以直接用 AccessKey 创建同一个 profile：

```sh
aliyun configure set \
  --profile my-aliyun \
  --mode AK \
  --access-key-id <your-access-key-id> \
  --access-key-secret <your-access-key-secret> \
  --region cn-hangzhou
```

不要使用主账号的 AccessKey，优先使用 RAM 用户或其他最小权限凭证来源。阿里云 CLI
会把 profile 保存在 macOS/Linux 的 `~/.aliyun/config.json`。

### 2. 这个示例里的 Terraform provider 是怎么设置的

这个示例没有把凭证硬编码进 Terraform，而是只配置了 region 和 CLI profile：

```hcl
provider "alicloud" {
  region  = var.alicloud_region
  profile = var.alicloud_profile
}
```

也就是说：

- `alicloud_region` 控制 provider 所使用的地域，默认值是 `cn-hangzhou`。
- `alicloud_profile` 用来选择本机阿里云 CLI 配置里的某个 profile。
- 如果你的机器上配置了多个 profile，最好显式传入 `alicloud_profile`，不要依赖本地
  当前默认 profile，避免行为不确定。

例如：

```sh
terraform plan \
  -var alicloud_region=cn-hangzhou \
  -var alicloud_profile=my-aliyun
```

如果你不想每次都写参数，也可以在当前 shell 会话里先设置：

```sh
export TF_VAR_alicloud_region=cn-hangzhou
export TF_VAR_alicloud_profile=my-aliyun
```

### 3. 切换 profile 的方式

如果你是想切换阿里云 CLI 自己的当前 profile，可以执行：

```sh
aliyun configure switch --profile my-aliyun
```

如果你是想让这个 Terraform 示例明确使用某个 profile，最直接的方式是每次执行时传参：

```sh
terraform plan -var alicloud_profile=my-aliyun
terraform apply -var alicloud_profile=my-aliyun
terraform destroy -var alicloud_profile=my-aliyun
```

如果一段时间内都要使用同一个 profile，也可以用 `TF_VAR_alicloud_profile`，这样就不
需要在每条 Terraform 命令后重复写同样的参数。

### 4. 修改 `oidc.tf` 里的 OIDC 值

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

### 5. 执行 Terraform

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
- [阿里云 CLI：配置凭证](https://www.alibabacloud.com/help/en/cli/configure-alibaba-cloud-cli/configure-credentials)
- [Terraform Registry：Alibaba Cloud provider 认证方式](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs)
