---
paths:
  - ".github/workflows/**/*.yml"
  - ".github/workflows/**/*.yaml"
---

# GitHub Actions Workflow Rules

## Workflow Structure

```
.github/workflows/
├── build-push.yml          # Build Docker images, push to ECR
├── update-image-tags.yml   # Commit image tag updates → ArgoCD deploys
└── reusable/               # Reusable workflow templates
```

## Architecture: CI (GitHub Actions) + CD (ArgoCD)

GitHub Actions handles **CI only**. ArgoCD handles **CD**. CI never runs `kubectl apply` or `helm upgrade`.

## Job Naming

- `build` — compile, test, build Docker image
- `scan` — vulnerability scanning (Trivy)
- `push` — push to ECR
- `update-tags` — commit updated image tags to `helm-values/{service}.yaml`

## Required Practices

1. **No secrets in YAML** — use GitHub Secrets and Environment variables
2. **AWS auth via OIDC** — use `aws-actions/configure-aws-credentials` with role-to-assume, never static keys
3. **No kubectl/helm in CI** — ArgoCD deploys. CI only builds, pushes, and commits image tags
4. **Image tags** — use commit SHA (`${{ github.sha }}` short form), never `latest`
5. **Reusable workflows** — common steps in `.github/workflows/reusable/` to avoid duplication
6. **Artifact retention** — scan results saved as workflow artifacts for audit
7. **ECR login** — `aws ecr get-login-password --region us-east-1`

## Trigger Patterns

- `build-push.yml`: trigger on push to `main` branch, path filter on application code
- `update-image-tags.yml`: trigger after successful build-push (`workflow_run`), commits new SHA tag to helm-values

## GitHub Secrets

- **Secrets:** `AWS_ROLE_ARN`, `AWS_REGION`, `ECR_REGISTRY`
- No EKS credentials needed in CI — ArgoCD runs in-cluster

## Error Handling

- Fail workflow on any non-zero exit code
- Fail workflow on Trivy CRITICAL findings
- On failure: do NOT retry automatically, notify team
