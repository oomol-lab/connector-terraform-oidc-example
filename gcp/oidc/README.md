# GCP OIDC example

Google Cloud's equivalent feature is Workload Identity Federation. It lets an
external OIDC token exchange into Google Cloud credentials without a service
account key.

This example creates:

- a Workload Identity Pool
- an OIDC Workload Identity Pool Provider for `https://api.oomol.com`
- a service account
- a `roles/iam.workloadIdentityUser` binding for one OIDC `sub` value

## Usage

Before running Terraform, update the user-specific values.

Values you must review:

| Value | Replace it? | What to use |
| --- | --- | --- |
| `project_id` | Yes. | The Google Cloud project ID that owns the Workload Identity Pool and service account. |
| `audience` | Yes. | The OOMOL OIDC audience configured in `oomol-connector`. It must match the token `aud` claim. |
| `oidc_issuer_uri` | No. | OOMOL's fixed issuer URI. It must match the token `iss` claim exactly. |
| `subject` | Yes. | Your OOMOL user UUID. It must match the token `sub` claim. |
| `service_account_id` | Usually no. | The Google service account ID to create for OOMOL impersonation. Change it only if you need a different account name. |

For example, create `terraform.tfvars`:

```hcl
project_id = "replace-with-your-gcp-project-id"
audience   = "replace-with-your-oomol-audience"
subject    = "replace-with-your-oomol-user-uuid"
```

Then run:

```sh
terraform init
terraform plan
terraform apply
```

Do not leave `subject` as a placeholder. The service account binding must check
the token `sub` claim; otherwise the provider can accept a broader set of OOMOL
tokens than intended.

After apply, put the Workload Identity Provider resource name and service
account email into `oomol-connector` to finish the OIDC integration.

Field mapping:

| Terraform value or output | `oomol-connector` field |
| --- | --- |
| `audience` | Google Cloud OIDC `audience` |
| `workload_identity_pool_provider_name` | Google Cloud STS audience provider resource. Prefix it with `//iam.googleapis.com/` when calling STS. |
| `service_account_email` | Google service account email to impersonate |

```sh
terraform output workload_identity_pool_provider_name
terraform output service_account_email
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
full provider resource name as the STS audience. This is the
`workload_identity_pool_provider_name` output with the `//iam.googleapis.com/`
prefix:

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

Use the returned service account access token to call Google Cloud APIs.

## Reference documentation

- [Google Cloud IAM: Workload Identity Federation](https://docs.cloud.google.com/iam/docs/workload-identity-federation)
- [Google Cloud IAM: Security Token Service token method](https://docs.cloud.google.com/iam/docs/reference/sts/rest/v1/TopLevel/token)
- [Google Cloud IAM: Service Account Credentials generateAccessToken](https://docs.cloud.google.com/iam/docs/reference/credentials/rest/v1/projects.serviceAccounts/generateAccessToken)
- [Google Cloud IAM: Workload Identity Federation with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- [Terraform Google provider: google_iam_workload_identity_pool_provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider)
