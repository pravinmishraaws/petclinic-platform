# Petclinic Platform — Claude Code Instructions

This repo contains ALL infrastructure code for deploying Spring Petclinic Microservices to AWS.
The application repo (spring-petclinic-microservices) is READ-ONLY — never modify it.

## Directory Layout

```
terraform/environments/{dev,prod}/   # Root modules (one per environment)
terraform/modules/{vpc,eks,ecr,rds,dns,secrets,observability,karpenter}/
helm/petclinic-service/              # Generic Helm chart (shared by all 8 services)
helm-values/                         # Per-service YAML + per-env (dev.yaml, prod.yaml)
k8s/base/                            # Namespaces, external-secrets CRs
k8s/argocd/install/                  # ArgoCD installation manifests
k8s/argocd/applications/{dev,prod}/  # ArgoCD Application CRDs
.github/workflows/                    # CI pipelines (build + push only, ArgoCD handles CD)
scripts/                             # Operational scripts
docs/                                # Architecture docs, runbooks, ADRs
```

## Terraform Conventions

- **Provider:** AWS provider ~> 5.0, region us-east-1
- **ECR:** Uses `aws_ecr_repository` in us-east-1 with lifecycle policies, scan-on-push, and configurable tag immutability
- **State:** S3 + DynamoDB locking, key pattern: `petclinic/{env}/terraform.tfstate`
- **Modules:** All reusable modules in `terraform/modules/`. Environments call modules.
- **Naming:** `petclinic-{env}-{resource}` (e.g., `petclinic-dev-vpc`, `petclinic-prod-eks`)
- **Tagging:** Every resource MUST have tags: `Project=petclinic`, `Environment={dev|prod}`, `ManagedBy=terraform`
- **Variables:** Use `variable` blocks with `description`, `type`, and `default` where sensible
- **Outputs:** Export IDs, ARNs, and endpoints needed by downstream modules
- **Sensitive values:** Never hardcode secrets. Use `sensitive = true` for secret outputs.
- **Formatting:** Run `terraform fmt` before committing. Use `terraform validate` after edits.
- **Files per module:** `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` (provider constraints)

## Kubernetes Conventions

- **Namespaces:** `petclinic-dev`, `petclinic-prod` (one namespace per environment)
- **Labels:** Every resource: `app.kubernetes.io/name`, `app.kubernetes.io/part-of=petclinic`, `app.kubernetes.io/managed-by=Helm`
- **Probes:** Every Deployment MUST have readinessProbe and livenessProbe using `/actuator/health/{readiness,liveness}`
- **Resources:** Every container MUST have requests and limits (memory: 128Mi request / 512Mi limit)
- **Image tags:** Use commit SHA tags, never `latest` in production
- **Secrets:** Use ExternalSecret CRs pointing to AWS Secrets Manager — never store secrets in YAML
- **Service startup order:** Config Server → Discovery Server → all others (use init containers)
- **Packaging:** Helm chart (`helm/petclinic-service/`), per-service + per-env values in `helm-values/`
- **Deployment:** ArgoCD GitOps — CI commits image tags to Git, ArgoCD syncs to cluster

## Helm Conventions

- **Single generic chart** in `helm/petclinic-service/` shared by all 8 services
- **Per-service config** in `helm-values/{service}.yaml` (ports, env vars, init containers)
- **Per-env config** in `helm-values/{dev,prod}.yaml` (replicas, HPA, PDB, resource quotas)
- **ArgoCD merges values:** service file + env file when deploying
- **Template outputs** validated with `helm template` before commit

## ArgoCD Conventions

- **CI pushes images**, ArgoCD deploys. GitHub Actions NEVER runs `kubectl apply`.
- **Dev:** auto-sync enabled (prune + self-heal)
- **Prod:** manual sync required (approval via ArgoCD UI/CLI)
- **Application CRDs** in `k8s/argocd/applications/{dev,prod}/`
- **One Application per service per environment** (16 total: 8 services × 2 envs)

## Security Rules (NON-NEGOTIABLE)

1. **No secrets in code** — use AWS Secrets Manager + External Secrets Operator
2. **No public S3 buckets** — block public access on all buckets
3. **No open security groups** — no 0.0.0.0/0 ingress except ALB on 80/443
4. **Encryption everywhere** — RDS encryption at rest, S3 SSE, EBS encryption
5. **Least privilege IAM** — specific actions on specific resources, never `*/*`
6. **Security groups are the perimeter** — all resources in public subnets (cost optimization for learning), SGs enforce access control
7. **No terraform destroy without approval** — hooks block this command
8. **No *.tfvars or .env files committed** — .gitignore enforces this

## AWS Environment Details

| Setting | Dev | Prod |
|---------|-----|------|
| Region | us-east-1 | us-east-1 |
| K8s namespace | petclinic-dev | petclinic-prod |
| State key | petclinic/dev/terraform.tfstate | petclinic/prod/terraform.tfstate |
| RDS instance | db.t4g.micro, single-AZ (free tier) | db.t4g.micro, single-AZ (free tier) |
| EKS nodes | 2x t4g.small ARM (Graviton free trial) | 2x t4g.small ARM (Graviton free trial) |
| Deploy mode | ArgoCD auto-sync | ArgoCD manual sync |
| Replicas | 1 per service | 2+ per service, HPA |

## Application Services (8 total)

| Service | Port | Needs MySQL | Notes |
|---------|------|-------------|-------|
| config-server | 8888 | No | Must start first, Git-backed config |
| discovery-server | 8761 | No | Eureka, must start second |
| api-gateway | 8080 | No | Frontend + routing, public-facing |
| customers-service | 8081 | Yes | Owners & pets |
| visits-service | 8082 | Yes | Visit records |
| vets-service | 8083 | Yes | Vet data, Caffeine cache |
| genai-service | 8084 | Optional | Needs OPENAI_API_KEY |
| admin-server | 9090 | No | Spring Boot Admin dashboard |

## Docker Image Details

- Base: `eclipse-temurin:17`, memory limit 512M
- **Target platform:** `linux/arm64` (required for Graviton t4g nodes)
- Profile: `SPRING_PROFILES_ACTIVE=docker` (set in container)
- MySQL profile: add `mysql` to active profiles for RDS-backed services
- ECR repos: `{account}.dkr.ecr.us-east-1.amazonaws.com/petclinic-{env}/{service-name}`
- CI/CD builds require `docker buildx` + QEMU for ARM cross-compilation on x86 runners

## Workflow Commands

```bash
# Terraform workflow (always plan before apply)
terraform fmt -recursive
terraform validate
terraform plan -out plan.out
terraform apply plan.out        # Never apply without a saved plan

# Helm template validation
helm template my-release helm/petclinic-service/ -f helm-values/{service}.yaml -f helm-values/{env}.yaml

# ArgoCD (after install)
kubectl port-forward svc/argocd-server -n argocd 8443:443
argocd app sync {service}-{env}

# Security scanning
checkov -d terraform/modules/{module}
```

## MCP Servers (configured in .mcp.json)

Five MCP servers configured at the project level:

| Server | Purpose |
|--------|---------|
| `awslabs.terraform-mcp-server` | AWS/AWSCC provider docs, Checkov scanning, terraform/terragrunt execution |
| `aws-knowledge-mcp` | AWS documentation search, regional availability, documentation reader |
| `awslabs.aws-pricing-mcp-server` | Cost estimation for AWS services (RDS, EKS, EC2, ALB) |
| `context7` | Up-to-date library documentation (Terraform, Kubernetes, Helm) |
| `atlassian` | Jira ticket lookup, creation, updates — drives the task-based workflow |

## CI/CD Pipeline Conventions

- **Architecture:** CI (GitHub Actions) + CD (ArgoCD). GitHub Actions NEVER deploys directly.
- **CI Platform:** GitHub Actions, OIDC federation to AWS (no long-lived credentials)
- **Image tags:** Commit SHA (`${GITHUB_SHA::7}`), never `latest`
- **ECR login:** `aws ecr get-login-password --region us-east-1` (same region as infrastructure)
- **Image tag update:** CI commits new tag to `helm-values/{service}.yaml` → ArgoCD picks up
- **Prod gates:** ArgoCD manual sync (not GitHub Environments)
- **Scanning:** Trivy scan after Docker build, fail on CRITICAL CVEs

## Safety Hooks (configured in .claude/settings.json)

| Hook | Type | What it catches |
|------|------|----------------|
| `block-destroy.sh` | Block | `terraform destroy`, `terraform apply -destroy`, `kubectl delete` ns/deploy/svc/ingress/secret in prod |
| `block-dangerous-rm.sh` | Block | `rm -rf` on terraform/, k8s/, helm/, helm-values/, .github/, .claude/ |
| `warn-apply-without-plan.sh` | Warn | `terraform apply` without saved plan.out file |
| `suggest-validate.sh` | Info | Suggests validate/dry-run after editing .tf, K8s .yaml, Helm, or pipeline files |
| `block-secret-commit.sh` | Block | `git add .`, committing .env, .tfvars, .pem, .key files |
| `block-mcp-destroy.sh` | Block | `destroy` via MCP Terraform/Terragrunt tools |

## Technical Specification

All infrastructure values (CIDRs, ports, instance sizes, security groups, K8s resources, probe timings, alert thresholds) are in [`docs/technical-spec.md`](docs/technical-spec.md). Every Jira story references the relevant spec section. **Read the spec before implementing any story.**

## Jira Backlog

Work is tracked in `docs/jira-backlog.md` (17 epics including Helm + ArgoCD, E-12 removed).
Dependency chain: E-0 → E-1 → VPC → EKS → K8s → Helm → ArgoCD; VPC → RDS → Secrets → K8s
