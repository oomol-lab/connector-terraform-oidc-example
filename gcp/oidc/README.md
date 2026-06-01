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

```sh
terraform init
terraform plan -var='project_id=my-gcp-project'
```

Override variables as needed:

```sh
terraform plan \
  -var='project_id=my-gcp-project' \
  -var='oidc_issuer_uri=https://api.oomol.com' \
  -var='allowed_audiences=["oomol"]' \
  -var='subject=oomol'
```

Before production use, replace `subject` with the final OOMOL `sub` claim value
and keep `allowed_audiences` aligned with the token `aud` claim. The service
account will still need project or resource-level IAM roles for the Google APIs
it should access.

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

Use the returned service account access token to call Google Cloud APIs.

## Reference documentation

- [Google Cloud IAM: Workload Identity Federation](https://docs.cloud.google.com/iam/docs/workload-identity-federation)
- [Google Cloud IAM: Security Token Service token method](https://docs.cloud.google.com/iam/docs/reference/sts/rest/v1/TopLevel/token)
- [Google Cloud IAM: Service Account Credentials generateAccessToken](https://docs.cloud.google.com/iam/docs/reference/credentials/rest/v1/projects.serviceAccounts/generateAccessToken)
- [Google Cloud IAM: Workload Identity Federation with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- [Terraform Google provider: google_iam_workload_identity_pool_provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider)
