# EC2-Behind-a-Load-Balancer

## CI

This repo includes a basic GitHub Actions workflow for Terraform checks.

On push or pull request, it runs:

- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`

This is intentionally CI-only. It does not run `terraform apply` or make changes to AWS.
