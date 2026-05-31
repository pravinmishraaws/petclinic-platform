# Jira Board — Petclinic Platform (PM View)

**Project Key:** PETPLAT
**Project Manager View** — PM tasks, priorities, and specifications for all 17 epics and 108 stories.
**Engineering detail:** see [`jira-backlog.md`](./jira-backlog.md).

---

## Project Summary

| Attribute | Value |
|-----------|-------|
| Total Epics | 17 (16 active, E-12 removed) |
| Total Stories/Tasks | 108 |
| Estimated Story Points | ~341 |
| Target Duration | 12 sprints (2 weeks each = ~6 months) |
| Team Size (assumed) | 2-3 engineers |
| Region | us-east-1 |
| AWS Account | 428101261622 |
| Budget Target | < $50 AWS spend for entire course |

### Priority Distribution

| Priority | Definition | Epics | Stories |
|----------|------------|-------|---------|
| P0 | Critical path — blocks all downstream work | 11 | 64 |
| P1 | Required for production readiness | 5 | 38 |
| P2 | Nice-to-have, can defer | 1 | 6 |

---

## Project Phases & Milestones

| Phase | Sprints | Epics | Milestone Demo |
|-------|---------|-------|----------------|
| **Phase 1 — Foundation** | Sprint 1-2 | E-0, E-1 | Terraform state working, Claude Code configured |
| **Phase 2 — Infrastructure** | Sprint 3-5 | E-2, E-3, E-4, E-5, E-7 | VPC + EKS + RDS + ECR + Secrets Manager deployed |
| **Phase 3 — Application** | Sprint 6-8 | E-8, E-9, E-16, E-17 | All 8 services running via ArgoCD GitOps |
| **Phase 4 — Operations** | Sprint 9-10 | E-6, E-10, E-11 | DNS/Ingress, CI pipeline, observability stack live |
| **Phase 5 — Hardening** | Sprint 11-12 | E-13, E-14, E-15 | Security audit complete, runbooks, DR test passed |

---

## Kanban Board View

### Backlog (Not Yet Started)
All 17 epics start here. PM moves to Sprint Planning when prerequisites are met.

### Sprint Planning Checklist (Per Epic)
- [ ] Acceptance criteria reviewed with team
- [ ] Story points estimated
- [ ] Dependencies confirmed unblocked
- [ ] Risks identified and logged
- [ ] Demo date scheduled

### In Progress
Active sprint work. Daily standups, blocker tracking.

### In Review
- [ ] Code review approved
- [ ] Terraform plan reviewed
- [ ] Security scan clean
- [ ] Documentation updated

### Done
- [ ] Demo'd to stakeholder
- [ ] Acceptance criteria signed off
- [ ] Story closed in Jira
- [ ] Retro item logged (if applicable)

---

# EPIC E-0: Claude Code Setup

**Priority:** P0
**Stories:** 5 (PETPLAT-001 to 004, PETPLAT-82)
**Story Points:** 14
**Phase:** 1 — Foundation
**Sprint:** 1
**Blocks:** All subsequent work

### PM Tasks
- [ ] Kickoff meeting — explain Claude Code role in the project
- [ ] Provision MCP server access (Atlassian token, AWS credentials)
- [ ] Schedule onboarding session for engineers on hooks and skills
- [ ] Capture team feedback on AI workflow effectiveness
- [ ] Sign off on safety hooks (block-destroy, secret-commit guards)

### Specifications
- CLAUDE.md exists at repo root with full conventions
- `.mcp.json` configured with 5 servers (Terraform, AWS Knowledge, Pricing, Context7, Atlassian)
- 6 safety hooks active and tested (block, warn, inform tiers)
- 4 file-pattern rules loaded (terraform, kubernetes, pipelines, docs)
- 9 skills available via slash commands
- 6 review subagents callable (terraform, k8s, security, cost, doc, pipeline)

### PM Acceptance
**Done when:** A new engineer can clone the repo, run `claude`, and immediately benefit from project context, hooks, and tooling without manual setup.

---

# EPIC E-1: Foundation & Remote State

**Priority:** P0
**Stories:** 5 (PETPLAT-1 to 5)
**Story Points:** 10
**Phase:** 1 — Foundation
**Sprint:** 1-2
**Blocks:** E-2, E-3, E-4, E-5, E-6, E-7

### PM Tasks
- [ ] Confirm AWS account access for team (428101261622)
- [ ] Approve S3 bucket and DynamoDB table naming
- [ ] Review remote state security posture with security lead
- [ ] Document state recovery procedure for handover
- [ ] Sign off on Terraform version pinning strategy

### Specifications
- `terraform/` directory structure created (environments/, modules/)
- S3 bucket `petclinic-terraform-state-{account-id}` with versioning + encryption + public access blocked
- DynamoDB table `petclinic-terraform-locks` for state locking
- `terraform init` succeeds for both dev and prod environments
- AWS provider pinned to `~> 5.0`, Terraform `>= 1.6.0`
- Common tags applied via `default_tags`: Project, Environment, ManagedBy

### PM Acceptance
**Done when:** Both environments can run `terraform plan` against an empty state file, and bootstrap script is idempotent and documented.

### Risks
- Risk: State bucket name collision (AWS S3 is global). Mitigation: include account ID suffix.
- Risk: Lock table region mismatch. Mitigation: enforce us-east-1 across all state config.

---

# EPIC E-2: Networking (VPC)

**Priority:** P0
**Stories:** 5 (PETPLAT-6, 8, 9, 10, 11) — PETPLAT-7 removed
**Story Points:** 13
**Phase:** 2 — Infrastructure
**Sprint:** 3
**Blocks:** E-3, E-5, E-6

### PM Tasks
- [ ] Review all-public subnet design with security stakeholder (ADR-0001)
- [ ] Document the cost-vs-security trade-off for handover team
- [ ] Confirm CIDR allocation does not conflict with future VPCs (10.0.0.0/16 dev, 10.1.0.0/16 prod)
- [ ] Approve security group rules with security lead
- [ ] Schedule VPC review with cloud architect

### Specifications
- VPC module reusable across environments
- 2 public subnets across 2 AZs (us-east-1a, us-east-1b)
- Internet Gateway + single route table (0.0.0.0/0 → IGW)
- 4 security groups: EKS cluster, EKS nodes, RDS (3306 from nodes only), ALB (80/443 from internet)
- Subnets tagged for EKS auto-discovery (`kubernetes.io/cluster/petclinic-{env}=shared`)
- No NAT Gateway, no VPC endpoints (cost optimization — saves $35-65/mo)

### PM Acceptance
**Done when:** `terraform apply` for dev produces a working VPC with all SGs, and a debug EC2 instance in the public subnet can reach the internet.

### Risks
- Risk: All-public design has weaker defense-in-depth. Mitigation: SGs enforce strict least-privilege; documented in ADR-0001.

---

# EPIC E-3: EKS Cluster

**Priority:** P0
**Stories:** 7 (PETPLAT-12 to 17, PETPLAT-84)
**Story Points:** 21
**Phase:** 2 — Infrastructure
**Sprint:** 3-4
**Blocks:** E-8, E-9, E-10, E-11

### PM Tasks
- [ ] Confirm EKS version choice with team (1.29)
- [ ] Schedule cluster access review (who needs kubectl)
- [ ] Approve node sizing and free trial usage (t4g.small Graviton)
- [ ] Document EKS upgrade cadence (quarterly review)
- [ ] Coordinate with security lead on OIDC provider setup
- [ ] Plan cost monitoring for EKS control plane (~$73/mo, unavoidable)

### Specifications
- EKS cluster `petclinic-{env}` on Kubernetes 1.29
- Managed node group: 2x t4g.small (ARM/Graviton free trial), min=2/max=4/desired=2
- OIDC provider configured for IRSA
- EKS managed add-ons: coredns, kube-proxy, vpc-cni, aws-ebs-csi-driver
- Cluster logging enabled (api, audit, authenticator)
- kubectl access via `aws eks update-kubeconfig`

### PM Acceptance
**Done when:** `kubectl get nodes` shows 2 Ready ARM64 nodes in both dev and prod clusters.

### Risks
- Risk: Graviton free trial expires Dec 2026. Mitigation: document migration to on-demand pricing or Karpenter spot diversification.

---

# EPIC E-4: Container Registry (ECR)

**Priority:** P0
**Stories:** 5 (PETPLAT-18 to 21, PETPLAT-85)
**Story Points:** 11
**Phase:** 2 — Infrastructure
**Sprint:** 3
**Blocks:** E-10, E-17

### PM Tasks
- [ ] Approve ECR naming convention (`petclinic-{env}/{service}`)
- [ ] Confirm tag immutability policy: MUTABLE dev / IMMUTABLE prod
- [ ] Review lifecycle policy (keep last 10 images, expire untagged after 7d)
- [ ] Coordinate initial image push timing with app team
- [ ] Schedule ECR scan-on-push results review

### Specifications
- 8 ECR private repositories per environment (16 total)
- Scan-on-push enabled
- Lifecycle policy: keep 10 images, expire untagged after 7 days
- Tag mutability per environment
- ECR login script for local development
- Initial v1.0.0 images pushed and verified

### PM Acceptance
**Done when:** All 8 ECR repos exist in dev with at least one image successfully pushed and visible in AWS Console.

---

# EPIC E-5: Database (RDS MySQL)

**Priority:** P0
**Stories:** 6 (PETPLAT-22 to 27)
**Story Points:** 16
**Phase:** 2 — Infrastructure
**Sprint:** 4
**Blocks:** E-7, E-8

### PM Tasks
- [ ] Review single-AZ choice with stakeholder (ADR-0006)
- [ ] Document Multi-AZ migration path for production scenarios
- [ ] Coordinate schema initialization strategy with app team
- [ ] Approve master credential rotation policy
- [ ] Sign off on backup retention (7d dev, 30d prod)
- [ ] Schedule RDS connectivity test from EKS pod

### Specifications
- MySQL 8.0 on db.t4g.micro (free tier eligible)
- Single shared `petclinic` database for customers, visits, vets services
- Encryption at rest (KMS default)
- Master credentials in Secrets Manager (`petclinic/{env}/rds-credentials`)
- Backup retention 7 days
- RDS SG allows 3306 from EKS node SG only

### PM Acceptance
**Done when:** A debug pod in EKS can connect to RDS using credentials retrieved from Secrets Manager and query a test table.

### Risks
- Risk: Single-AZ means downtime during maintenance. Mitigation: documented in ADR-0006 as cost trade-off for learning project.

---

# EPIC E-6: DNS & Ingress

**Priority:** P1
**Stories:** 5 (PETPLAT-28 to 32)
**Story Points:** 14
**Phase:** 4 — Operations
**Sprint:** 9
**Blocks:** E-8 (ingress manifests)

### PM Tasks
- [ ] Procure domain name or confirm existing one for project
- [ ] Coordinate ACM certificate validation (DNS-validated)
- [ ] Schedule ALB cost review
- [ ] Document DNS delegation if subdomain is used
- [ ] Sign off on TLS termination at ALB

### Specifications
- Route 53 hosted zone for project domain
- ACM wildcard certificate, DNS-validated
- AWS Load Balancer Controller installed via Helm with IRSA
- Ingress resource routes `/` → api-gateway:8080
- HTTPS enforced (HTTP → HTTPS redirect)
- Route 53 alias record points domain to ALB

### PM Acceptance
**Done when:** `https://petclinic-dev.{domain}` returns the AngularJS frontend served via the API Gateway over a valid TLS connection.

---

# EPIC E-7: Secrets Management (Secrets Manager)

**Priority:** P0
**Stories:** 6 (PETPLAT-33 to 37, PETPLAT-98)
**Story Points:** 17
**Phase:** 2 — Infrastructure
**Sprint:** 4-5
**Blocks:** E-8

### PM Tasks
- [ ] Procure OpenAI API key for GenAI service
- [ ] Document secret rotation policy (30d for RDS automated, manual for others)
- [ ] Approve IRSA role permissions scope
- [ ] Schedule ESO rollout review with team
- [ ] Set up Secrets Manager cost alert (~$1.20/mo expected)
- [ ] Sign off on secret naming convention (`petclinic/{env}/{name}`)

### Specifications
- 2 secrets per environment: `rds-credentials` (JSON), `openai-api-key` (plaintext)
- External Secrets Operator deployed to `external-secrets` namespace
- ClusterSecretStore configured with AWS Secrets Manager provider
- IRSA role for ESO with scoped `secretsmanager:GetSecretValue`
- ExternalSecret CRs for RDS credentials and OpenAI key
- Refresh interval: 1 hour

### PM Acceptance
**Done when:** A pod can read RDS credentials and OpenAI key as environment variables that originate from Secrets Manager (verified by rotating the secret and observing the K8s Secret update).

---

# EPIC E-8: Kubernetes Manifests — Base

**Priority:** P0
**Stories:** 8 (PETPLAT-38 to 44, PETPLAT-86)
**Story Points:** 22
**Phase:** 3 — Application
**Sprint:** 6
**Blocks:** E-9, E-10, E-11

### PM Tasks
- [ ] Confirm service inventory matches app team's understanding (8 services)
- [ ] Approve startup order strategy (init containers vs ArgoCD sync waves)
- [ ] Schedule manifest review with platform engineer
- [ ] Coordinate smoke test execution with QA
- [ ] Document service dependency chain for handover

### Specifications
- 8 service directories under `k8s/base/`
- Each service: Deployment, Service, ConfigMap, ServiceAccount
- All deployments include startup/readiness/liveness probes
- Resource requests + limits per service (per technical-spec.md)
- Init containers enforce startup order (Config → Discovery → Apps)
- SecurityContext: runAsNonRoot, drop ALL capabilities
- Smoke test script validates all 8 services healthy

### PM Acceptance
**Done when:** All 8 services deploy to `petclinic-dev`, register with Eureka, and the smoke test passes end-to-end.

---

# EPIC E-9: Kubernetes Manifests — Overlays

**Priority:** P1
**Stories:** 5 (PETPLAT-45 to 48, PETPLAT-88, PETPLAT-89)
**Story Points:** 18
**Phase:** 3 — Application
**Sprint:** 7
**Blocks:** E-14, E-16

### PM Tasks
- [ ] Approve replica counts per environment (1 dev / 2+ prod)
- [ ] Review HPA targets with capacity planning input
- [ ] Schedule load test to validate HPA behavior
- [ ] Document PDB strategy for prod node drains
- [ ] Sign off on ResourceQuota and LimitRange values

### Specifications
- Dev overlay: 1 replica, no HPA, no PDB
- Prod overlay: 2+ replicas, HPA enabled, PDB minAvailable=1
- HPA targets: api-gateway 70% CPU, max 6; domain services max 4
- ResourceQuota per namespace (max CPU, memory, pods)
- LimitRange enforces default requests for all containers
- Settings translate cleanly into Helm values (E-16)

### PM Acceptance
**Done when:** Prod deployment survives a simulated node drain with zero downtime, and HPA scales api-gateway under load test.

---

# EPIC E-10: CI Pipeline (CI-only, ArgoCD handles CD)

**Priority:** P0
**Stories:** 7 (PETPLAT-49, 50, 52, 53, 54, 87, 105) — PETPLAT-51 removed
**Story Points:** 25
**Phase:** 4 — Operations
**Sprint:** 9-10
**Blocks:** None

### PM Tasks
- [ ] Coordinate GitHub repo access and branch protection rules
- [ ] Approve OIDC IAM role permissions with security lead
- [ ] Schedule CI cost review (GitHub Actions minutes usage)
- [ ] Document rollback procedure (Git revert vs ArgoCD UI rollback)
- [ ] Sign off on Trivy CVE gating policy (fail on CRITICAL)
- [ ] Coordinate `repository_dispatch` setup between app and platform repos

### Specifications
- `build-push.yml` in app repo: builds ARM64 images, scans with Trivy, pushes to ECR
- `update-image-tags.yml` in platform repo: commits SHA to `helm-values/{service}.yaml`
- OIDC federation — no long-lived AWS credentials
- Only changed services build (paths-filter)
- Image tag = 7-char commit SHA, never `latest`
- No `kubectl apply` anywhere in CI — strictly GitOps
- Rollback documented: Git revert → ArgoCD syncs prior version

### PM Acceptance
**Done when:** A code commit in the app repo flows automatically through CI, lands in ECR, updates helm-values, and is deployed to dev by ArgoCD within 10 minutes.

### Risks
- Risk: ARM cross-compilation slow on x86 runners (~5 min/image). Mitigation: accepted for learning project; can move to ARM runners later.

---

# EPIC E-11: Observability

**Priority:** P1
**Stories:** 8 (PETPLAT-55 to 60, PETPLAT-97, PETPLAT-103) — PETPLAT-61 removed
**Story Points:** 30
**Phase:** 4 — Operations
**Sprint:** 9-10
**Blocks:** None

### PM Tasks
- [ ] Approve in-cluster logging choice (Loki) over CloudWatch (ADR-0011)
- [ ] Coordinate notification channel setup (email minimum, Slack preferred)
- [ ] Schedule dashboard walkthrough with on-call engineers
- [ ] Document alert response SLAs (Critical 15m, Warning 1h)
- [ ] Sign off on log retention (7d dev, 30d prod)
- [ ] Review observability stack cost (~$2/mo for EBS PVs)

### Specifications
- Prometheus scrapes all 8 services on `/actuator/prometheus`
- Grafana with Prometheus + Loki datasources
- Per-service dashboards + overview dashboard + JVM dashboard
- Alertmanager routes critical → immediate, warning → batched
- Loki + FluentBit DaemonSet for centralized logs
- Zipkin for distributed tracing (port 9411)
- Monitoring & alerting guide documented

### PM Acceptance
**Done when:** A simulated service failure triggers an alert that reaches the configured channel within 1 minute, and on-call engineer can locate root cause via Grafana/Loki in under 5 minutes.

---

# ~~EPIC E-12: Bastion Host~~ — REMOVED

**Reason:** Not needed. kubectl runs locally; RDS debugging via `kubectl run debug --image=mysql:8`; emergency access via AWS SSM Session Manager. Saves ~$15/mo + eliminates SSH key management.

---

# EPIC E-13: Security & Compliance

**Priority:** P1
**Stories:** 8 (PETPLAT-66 to 71, PETPLAT-100, PETPLAT-101)
**Story Points:** 25
**Phase:** 5 — Hardening
**Sprint:** 11
**Blocks:** None (parallel after E-3)

### PM Tasks
- [ ] Schedule security audit with external reviewer (or security lead)
- [ ] Coordinate Checkov findings triage session
- [ ] Approve compliance checklist as handover artifact
- [ ] Document remediation SLAs (Critical 24h, High 72h, Medium 1wk)
- [ ] Sign off on Pod Security Admission enforcement (baseline mode)
- [ ] Review network policies with team

### Specifications
- Checkov scan: all CRITICAL findings fixed, HIGH documented
- K8s NetworkPolicies: default deny + explicit allow rules
- IAM least privilege: no wildcards in actions/resources
- ECR scan-on-push + Trivy CI gate on CRITICAL CVEs
- SG audit: no 0.0.0.0/0 except ALB 80/443
- Pod Security Admission: enforce=baseline, warn=restricted
- Compliance checklist covers encryption, IAM, audit logging, data classification

### PM Acceptance
**Done when:** Security review checklist is signed off, all CRITICAL/HIGH findings are resolved or documented, and the compliance checklist is published.

---

# EPIC E-14: Scaling & Cost Optimization (Karpenter)

**Priority:** P2
**Stories:** 6 (PETPLAT-72 to 76, PETPLAT-102)
**Story Points:** 23
**Phase:** 5 — Hardening
**Sprint:** 12
**Blocks:** None

### PM Tasks
- [ ] Confirm Karpenter over Cluster Autoscaler (ADR-0009)
- [ ] Schedule load test to validate scaling behavior
- [ ] Approve budget alert thresholds ($100/env, alert at 50/80/100%)
- [ ] Document spot interruption handling expectations
- [ ] Coordinate cost report cadence with finance/stakeholder

### Specifications
- Metrics Server installed (HPA dependency)
- Karpenter installed with IRSA + SQS interruption queue + EventBridge rules
- NodePool + EC2NodeClass CRDs (ARM64 only initially)
- Spot capacity-type added when Graviton free trial expires
- CloudWatch budget alerts at 50/80/100% of $100/env
- Cost breakdown documented in architecture doc
- Load test framework (k6) with baseline results

### PM Acceptance
**Done when:** Karpenter provisions a new node within 60 seconds of unschedulable pods being detected, and budget alerts fire correctly when threshold is exceeded.

---

# EPIC E-15: Documentation & Runbooks

**Priority:** P1
**Stories:** 11 (PETPLAT-77 to 81, PETPLAT-90, 91, 92, 99, 104, PETPLAT-82)
**Story Points:** 35
**Phase:** 5 — Hardening (ongoing throughout project)
**Sprint:** 1-12 (continuous)
**Blocks:** None

### PM Tasks
- [ ] Establish doc review cadence (every 2 sprints)
- [ ] Coordinate handover dry-run with target team
- [ ] Schedule DR test (PETPLAT-90) end of project
- [ ] Approve ADRs as decisions are made (don't batch at end)
- [ ] Document escalation paths and on-call contacts
- [ ] Sign off on onboarding guide (target: new engineer productive in ≤90 min)

### Specifications
- `architecture.md` — diagrams, component relationships, tech decisions
- `runbook.md` — restart, scale, rollback, secret rotation, EKS upgrade
- `incident-playbook.md` — common failures + RCA template + escalation
- `onboarding.md` — 90-minute new-engineer guide
- 11 ADRs in `adr/` covering all major decisions
- `monitoring-alerting-guide.md` — alerts, dashboards, channels
- `secret-rotation.md` — RDS auto-rotation + manual procedures
- `disaster-recovery.md` — RTO/RPO, backup, recovery procedures
- `compliance-checklist.md` — security controls inventory
- DR test executed and findings incorporated

### PM Acceptance
**Done when:** An engineer unfamiliar with the project can complete the onboarding guide in ≤90 minutes and successfully deploy a code change to dev.

---

# EPIC E-16: Helm Charts

**Priority:** P0
**Stories:** 5 (PETPLAT-107 to 111)
**Story Points:** 22
**Phase:** 3 — Application
**Sprint:** 7-8
**Blocks:** E-17

### PM Tasks
- [ ] Approve Helm over Kustomize decision (ADR-0007)
- [ ] Review chart structure with platform engineer
- [ ] Schedule Helm template validation walkthrough
- [ ] Document chart versioning policy
- [ ] Sign off on values hierarchy (defaults < per-service < per-env)

### Specifications
- Single generic chart `helm/petclinic-service/`
- Templates: Deployment, Service, ConfigMap, ServiceAccount, HPA, PDB
- 8 per-service values files + 2 per-env values files (dev, prod)
- HPA/PDB conditional on values
- `helm lint` passes; `helm template` renders valid YAML for all 16 combinations
- `scripts/validate-helm.sh` automates validation
- Helm usage and conventions documented

### PM Acceptance
**Done when:** All 8 services can be deployed to both environments using only `helm install` with the chart + values files, and the validation script passes 16/16 combinations.

---

# EPIC E-17: GitOps with ArgoCD

**Priority:** P0
**Stories:** 5 (PETPLAT-112 to 116)
**Story Points:** 21
**Phase:** 3 — Application
**Sprint:** 8
**Blocks:** None (but is the deployment mechanism for everything)

### PM Tasks
- [ ] Approve ArgoCD over alternatives (Flux, manual) — ADR-0008
- [ ] Coordinate ArgoCD admin access and initial password rotation
- [ ] Schedule GitOps loop demo for stakeholders
- [ ] Document prod sync approval workflow
- [ ] Sign off on RBAC: developers can sync dev, only admins sync prod
- [ ] Coordinate ArgoCD upgrade cadence (quarterly)

### Specifications
- ArgoCD installed in `argocd` namespace, version pinned
- 16 Application CRDs (8 services × 2 envs)
- Dev: `automated` sync policy (prune + selfHeal)
- Prod: `manual` sync policy (explicit approval required)
- RBAC restricts prod sync to admin role
- Initial admin password rotated, documented
- End-to-end GitOps loop tested and time-measured (target <10 min for dev)

### PM Acceptance
**Done when:** A push to the app repo triggers the full CI/CD chain ending with the new version running in dev (auto-sync) and queued for prod (manual sync), with sync history visible in ArgoCD UI.

---

## Cross-Cutting PM Activities

These run throughout the project, not tied to a single epic.

### Sprint Cadence
| Ceremony | Frequency | Duration | Attendees |
|----------|-----------|----------|-----------|
| Sprint Planning | Every 2 weeks | 2h | Full team + PM |
| Daily Standup | Daily | 15m | Engineers + PM |
| Sprint Review/Demo | End of sprint | 1h | Team + stakeholders |
| Sprint Retrospective | End of sprint | 1h | Team + PM |
| Backlog Grooming | Mid-sprint | 1h | PM + tech lead |
| ADR Review | As needed | 30m | Architect + PM |

### Stakeholder Communications
- **Weekly status email**: completed stories, blockers, upcoming work, budget status
- **Phase completion demo**: stakeholder sign-off before moving to next phase
- **Risk register update**: monthly review with stakeholders
- **Cost report**: weekly during active sprints, monthly otherwise

### Definition of Done (Universal)
A story is Done when ALL of the following are true:
- [ ] Acceptance criteria met
- [ ] Code reviewed and merged
- [ ] Tests pass (unit, integration, security scan)
- [ ] Documentation updated
- [ ] Demo'd to PM/stakeholder
- [ ] Deployed to dev environment (where applicable)
- [ ] No new CRITICAL security findings introduced
- [ ] Jira story closed

### Project Risk Register

| ID | Risk | Probability | Impact | Mitigation | Owner |
|----|------|-------------|--------|------------|-------|
| R1 | AWS budget overrun ($50 target) | Medium | High | Daily cost alerts, terraform destroy after sessions | PM |
| R2 | Graviton free trial expires (Dec 2026) | High | Medium | Migrate to spot via Karpenter (E-14) before expiry | Tech Lead |
| R3 | RDS single-AZ outage during demo | Low | High | Communicate maintenance window risk; documented in ADR-0006 | PM |
| R4 | ARM cross-compilation slow in CI | High | Low | Accepted; consider ARM runners later | Tech Lead |
| R5 | Team unfamiliar with ArgoCD | Medium | Medium | Schedule training session before E-17 sprint | PM |
| R6 | Secrets Manager misconfiguration leaks secrets | Low | Critical | IRSA scope review; Checkov scan; quarterly audit | Security |
| R7 | Helm chart breaks on K8s upgrade | Medium | Medium | `helm template` in CI; pin chart API versions | Platform |
| R8 | DR test reveals untested manual steps | High | Medium | Schedule DR test in Sprint 11; bake findings into runbook | PM |

### Budget Tracking

| Phase | Budget | Actual | Variance |
|-------|--------|--------|----------|
| Phase 1 — Foundation | $5 | TBD | — |
| Phase 2 — Infrastructure | $20 | TBD | — |
| Phase 3 — Application | $10 | TBD | — |
| Phase 4 — Operations | $10 | TBD | — |
| Phase 5 — Hardening | $5 | TBD | — |
| **Total** | **$50** | TBD | — |

---

## Priority Lanes Summary

### P0 Lane (Critical Path — Must Complete First)
E-0 → E-1 → E-2 → E-3 → E-4 → E-5 → E-7 → E-8 → E-16 → E-17 → E-10

64 stories. Blocks the entire project if any P0 epic slips.

### P1 Lane (Production Readiness)
E-6, E-9, E-11, E-13, E-15

38 stories. Required before declaring the platform production-ready, but does not block P0 work.

### P2 Lane (Nice-to-Have)
E-14

6 stories. Can be deferred to a future iteration if timeline is tight.

---

## Story Index (108 Total)

See [`jira-backlog.md`](./jira-backlog.md) for complete acceptance criteria, dependencies, and technical specs for each story.

| Epic | Story Range | Count |
|------|-------------|-------|
| E-0 | PETPLAT-001 to 004, 82 | 5 |
| E-1 | PETPLAT-1 to 5 | 5 |
| E-2 | PETPLAT-6, 8-11 | 5 |
| E-3 | PETPLAT-12 to 17, 84 | 7 |
| E-4 | PETPLAT-18 to 21, 85 | 5 |
| E-5 | PETPLAT-22 to 27 | 6 |
| E-6 | PETPLAT-28 to 32 | 5 |
| E-7 | PETPLAT-33 to 37, 98 | 6 |
| E-8 | PETPLAT-38 to 44, 86 | 8 |
| E-9 | PETPLAT-45 to 48, 88, 89 | 5 |
| E-10 | PETPLAT-49, 50, 52-54, 87, 105 | 7 |
| E-11 | PETPLAT-55 to 60, 97, 103 | 8 |
| E-12 | REMOVED | 0 |
| E-13 | PETPLAT-66 to 71, 100, 101 | 8 |
| E-14 | PETPLAT-72 to 76, 102 | 6 |
| E-15 | PETPLAT-77 to 81, 90, 91, 92, 99, 104 | 11 |
| E-16 | PETPLAT-107 to 111 | 5 |
| E-17 | PETPLAT-112 to 116 | 5 |
| **Total** | | **108** |

---

## Sign-Off Matrix

| Phase | Sign-Off Required From | Demo Artifact |
|-------|------------------------|---------------|
| Phase 1 — Foundation | Tech Lead | `terraform init` working in both envs |
| Phase 2 — Infrastructure | Tech Lead + Security | VPC, EKS, RDS, ECR, Secrets all green in AWS Console |
| Phase 3 — Application | Tech Lead + App Team | All 8 services running via ArgoCD, smoke test passing |
| Phase 4 — Operations | Tech Lead + On-Call Eng | CI/CD loop demo, observability alerts working |
| Phase 5 — Hardening | Security + PM | Security checklist signed, DR test passed, runbooks complete |
| **Project Close** | All stakeholders | Onboarding guide validated by new engineer in ≤90 min |
