# GCP OIDC example

Google Cloud's equivalent feature is Workload Identity Federation. It lets an
external OIDC token exchange into Google Cloud credentials without a service
account key.

This example creates:

- a Workload Identity Pool
- an OIDC Workload Identity Pool Provider for `https://token.oomol.com`
- a service account
- a `roles/iam.workloadIdentityUser` binding for one OIDC `sub` value
- a minimal project custom role that allows `resourcemanager.projects.get`

## Usage

Before running Terraform, update the user-specific values.

Values you must review:

| Value | Replace it? | What to use |
| --- | --- | --- |
| `project_id` | Yes. | The Google Cloud project ID that owns the Workload Identity Pool and service account. |
| `oidc_issuer_uri` | No. | OOMOL's fixed issuer URI. It must match the token `iss` claim exactly. |
| `audience` | Usually yes. | Your OOMOL OIDC audience. Leave it empty only when using the Google STS audience. |
| `subject` | Yes. | Your OOMOL user UUID. It must match the token `sub` claim. |
| `service_account_id` | Usually no. | The Google service account ID to create for OOMOL impersonation. Change it only if you need a different account name. |
| `test_role_permissions` | Usually. | The concrete Google Cloud permissions OOMOL needs. Leave the default to use the minimal project metadata read test permission. |

For example, create `terraform.tfvars`:

```hcl
project_id = "replace-with-your-gcp-project-id"
audience   = "replace-with-your-oomol-audience"
subject    = "replace-with-your-oomol-user-uuid"

test_role_permissions = [
  "resourcemanager.projects.get",
]
```

Then run:

```sh
terraform init
terraform plan
terraform apply
```

Do not leave `audience` or `subject` as a placeholder. If you do not have a
custom OIDC audience, set `audience = ""`; Terraform will output the Google STS
audience instead. The provider checks the token `aud` claim, and the service
account binding checks the token `sub` claim; otherwise the provider can accept
a broader set of OOMOL tokens than intended.

The included project custom role is intentionally minimal. It only allows
`resourcemanager.projects.get` on the current project, which is enough to verify
that the impersonated service account has usable Google Cloud API permissions.
Use the service account access token to verify the test permission:

```sh
curl \
  -H "Authorization: Bearer <SERVICE_ACCOUNT_ACCESS_TOKEN>" \
  "https://cloudresourcemanager.googleapis.com/v1/projects/<PROJECT_ID>"
```

Override `test_role_permissions` with the concrete Google Cloud permissions
OOMOL needs for real workloads.

After apply, put the OIDC audience and service accounts into
`oomol-connector` to finish the integration.

Field mapping:

| Terraform value or output | `oomol-connector` field |
| --- | --- |
| `oidc_audience` | OIDC audience |
| `service_accounts` | Service accounts |
| `workload_identity_pool_provider_name` | Workload identity pool provider name |

```sh
terraform output oidc_audience
terraform output service_accounts
terraform output workload_identity_pool_provider_name
```

The service account will still need project or resource-level IAM roles for the
Google APIs it should access.

## Token exchange API

After the OIDC provider is configured, exchange the OOMOL OIDC token through
Google Cloud Security Token Service:

```http
POST https://sts.googleapis.com/v1/token
```

Use `urn:ietf:params:oauth:grant-type:token-exchange` as the grant type and the
full provider resource name as the STS audience:

```json
{
  "grantType": "urn:ietf:params:oauth:grant-type:token-exchange",
  "audience": "//iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/<POOL_ID>/providers/<PROVIDER_ID>",
  "scope": "https://www.googleapis.com/auth/cloud-platform",
  "requestedTokenType": "urn:ietf:params:oauth:token-type:access_token",
  "subjectTokenType": "urn:ietf:params:oauth:token-type:idToken",
  "subjectToken": "<OOMOL_OIDC_TOKEN>"
}
```

The response `access_token` is a federated Google access token. Because this
example grants the external principal `roles/iam.workloadIdentityUser` on a
service account, use that federated token to impersonate the service account via
the IAM Service Account Credentials API:

```http
POST https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/<SERVICE_ACCOUNT_EMAIL>:generateAccessToken
Authorization: Bearer <STS_ACCESS_TOKEN>
```

```json
{
  "scope": [
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}
```

Use the returned service account access token to call Google Cloud APIs. This
example grants that service account `resourcemanager.projects.get`, so the
token can read the current project's metadata as a minimal end-to-end
permission test.

## Reference documentation

- [Google Cloud IAM: Workload Identity Federation](https://docs.cloud.google.com/iam/docs/workload-identity-federation)
- [Google Cloud IAM: Security Token Service token method](https://docs.cloud.google.com/iam/docs/reference/sts/rest/v1/TopLevel/token)
- [Google Cloud IAM: Service Account Credentials generateAccessToken](https://docs.cloud.google.com/iam/docs/reference/credentials/rest/v1/projects.serviceAccounts/generateAccessToken)
- [Google Cloud IAM: Workload Identity Federation with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- [Terraform Google provider: google_iam_workload_identity_pool_provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider)
- [Terraform Google provider: google_project_iam_custom_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role)
