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

## Reference documentation

- [Google Cloud IAM: Workload Identity Federation](https://docs.cloud.google.com/iam/docs/workload-identity-federation)
- [Google Cloud IAM: Workload Identity Federation with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- [Terraform Google provider: google_iam_workload_identity_pool_provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider)
