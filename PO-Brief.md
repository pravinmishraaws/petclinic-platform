# Product Owner Brief – DevOps Cohort
**Project:** Spring Petclinic Microservices on **AWS**  
**Version:** v1.0 • **Owner (Business Owner):** Pravin Mishra , Akash Sharma 
**Product Owners:** `<PO-1 Name>`, `<PO-2 Name>`  
**Date:** 2025-09-14

**Primary Repository (students open PRs here):** https://github.com/pravinmishraaws/petclinic-platform

---

## 1) Executive Summary
Deliver a production-style deployment of the Spring Petclinic microservices on **AWS** using only the tools covered in the cohort. Start with a **manual bring-up on EC2** to build intuition; then progress to Docker + ECR, Terraform + EKS, Azure DevOps multi-stage deploys, and an Observability baseline (Prometheus + Grafana; Zipkin optional if taught). Documentation is a **first-class deliverable**.

---

## 2) Objectives & Non-Objectives
**Objectives**
- Hands-on, end-to-end DevOps workflow on AWS: plan → build → deploy → observe → operate.
- Make a new joiner productive in **≤ 90 minutes** via complete docs and runbooks.
- Demonstrate safe defaults (least privilege, immutable images, probes, resource limits).

**Non-Objectives**
- No Helm, Argo/Flux, GitHub Actions, or service mesh.
- No multi-cloud in this phase (AWS only).

---

## 3) Success Criteria (measurable)
- **Onboarding time:** ≤ 90 minutes using docs to deploy to **dev** and open dashboards.
- **Deploy time:** Build → push → deploy to dev in **≤ 10 minutes** on green path.
- **SLO placeholders (dev/staging):** p95 latency < 300ms; error rate < 1% under smoke load.
- **Docs quality:** All stories have **Doc Evidence URL(s)**; runbook/playbook complete and accurate.
- **Demo:** Working UI from **prod** with a short scripted flow.

---

## 4) Scope (course-aligned tools only)
- **Linux**, **Git & GitHub**, **Scrum (Taiga)**
- **AWS:** EC2, IAM, Security Groups, ECR, EKS, (Route 53 optional)
- **Terraform (IaC):** remote state S3 + DynamoDB; VPC; EKS; ECR
- **Ansible:** ops VM bootstrap/hardening & tooling
- **Azure DevOps (CI/CD):** multi-stage pipelines (build, push, deploy)
- **Docker:** multi-stage images to ECR
- **Kubernetes:** plain YAML + `kubectl` deploys (no Helm)
- **Observability:** Prometheus + Grafana (Zipkin optional)

---

## 5) Timeline & Milestones (6 sprints, 1 week each)
| Sprint | Milestone | What “Done” looks like |
|---|---|---|
| 1 | **Manual Bring-Up on EC2** | UI on 8080, Eureka on 8761, docs complete |
| 2 | **Dockerize & Push to ECR** | Images built, pushed by Azure DevOps |
| 3 | **Terraform: VPC + EKS + Remote State** | EKS reachable; state locked in S3 + DynamoDB |
| 4 | **K8s Deploy via Azure DevOps** | dev → staging → prod pipeline with approvals |
| 5 | **Observability** | Prometheus/Grafana live; 1 dashboard + alert per service |
| 6 | **Hardening & Release** | RBAC, probes, limits, secrets; release notes & demo |

> POs may adjust sprint length if needed (keep milestones intact).

---

## 6) Governance & Roles
**Business Owner (Pravin Mishra)** – sets priorities, accepts milestones, final sign-off.  
**Product Owners (2×)** – own backlog, define AC, verify docs, run reviews.  
**Leads** – Dev Lead (app), Infra (Terraform), CI/CD, SRE/Observability, Security Champion, QA.

**RACI (docs)**  
**A:** Business Owner, Product Owners • **R:** Respective Leads • **C:** Engineers • **I:** Cohort

---

## 7) Ways of Working (Taiga + Git)
- **Process:** Scrum in **Taiga**; daily standup; weekly grooming, review, retro.  
- **Issue Types:** Epic, User Story, Task, Bug, **Doc Task**.  
- **Workflow:** Backlog → Selected → In Progress → In Review → Ready for Test → Done.  
- **Repositories (GitHub):**  
  - `petclinic-platform` (primary, students open PRs): https://github.com/pravinmishraaws/petclinic-platform  
  - `petclinic-upstream` (vendored app fork, maintainers only): https://github.com/pravinmishraaws/petclinic-upstream (planned)  
- **Branching:** Trunk-based; `main` protected; PR review required; Conventional Commits.  
- **Evidence:** Every Story must add **Doc Evidence URL(s)** before “Done”.

---

## 8) Documentation Standard (docs-as-code)
All docs live in the repos (`/docs`). **POs reject any work without docs.**

Required pages (platform repo unless noted):
- `docs/00-overview.md` (what, why, links)  
- `docs/01-architecture.md` (context/component/deployment diagrams)  
- `docs/02-application-flow.md` (key user flows)  
- `docs/03-database.md` (HSQLDB default; MySQL optional)  
- `docs/04-security.md` (IAM/RBAC, secrets, network)  
- `docs/05-observability.md` (metrics, dashboards, alerts)  
- `docs/06-ci-cd.md` (stages, approvals, variables)  
- `docs/07-operations-runbook.md` (operate/rollback/scale/health)  
- `docs/08-known-issues-playbook.md` (top failures + commands)  
- `docs/09-onboarding.md` (≤ 90-min checklist)  
- `docs/10-release-notes.md` (per milestone)  
- `docs/adr/` (e.g., `0001-eks-vs-aks.md`, `0002-secrets-strategy.md`)  
- `petclinic-iac/docs/*` – backend, networking, cluster, DNS (if you split repos later)  
- `petclinic-ops/docs/*` – ops VM, SSH/access policy, Ansible (if you split repos later)

**Definition of Done (docs)**
- Pages updated with commands/examples/screenshots/links.  
- Runbook/Playbook updated if behavior/operations changed.

---

## 9) Backlog Structure (Epics)
1. **Foundations & Ways of Working**  
2. **Terraform Infrastructure (AWS)**  
3. **Ansible Ops VM & Access**  
4. **Containerization & Registry**  
5. **Kubernetes Deployments**  
6. **Observability**  
7. **Security & Compliance Baseline**  
8. **Documentation & Handover**

Each Epic includes explicit **Doc Tasks** and **Exit Criteria**.

---

## 10) Environment & Access Strategy (AWS)
- **Envs:** `dev` → `staging` → `prod` (promotion via Azure DevOps approvals).  
- **Networking:** VPC with public/private subnets; SGs restricted to team IPs.  
- **Registry:** **ECR**; immutable tags (commit SHA; digest pinning later).  
- **Cluster:** **EKS** with managed node group; `app-dev|stg|prod` namespaces.  
- **Secrets:** **AWS Secrets Manager** (no plaintext in repo/pipeline).

---

## 11) CI/CD Expectations (Azure DevOps)
- **Build:** Maven package → Docker build (multi-stage) → push to ECR.  
- **Deploy (kubectl):** dev → staging → prod (manual approvals on staging/prod).  
- **Quality gates:** build/test green; image pushed; deploy logs clean; smoke test passed.  
- **Variables/Secrets:** Library/Variable Groups or Secrets Manager-sourced env vars.

---

## 12) Observability Expectations
- **Prometheus** scrapes Micrometer metrics; **Grafana** dashboards committed as JSON.  
- **Per-service dashboard** (RPS, error rate, p95 latency) + **1 alert/service**.  
- **Runbook** links every dashboard and query; add a quick “graph-to-action” guide.  
- **Optional:** **Zipkin** if tracing was covered (keep minimal).

---

## 13) Security & Operational Baseline
- **IAM/RBAC:** least privilege; service accounts per service; no wildcards.  
- **K8s:** liveness/readiness probes; resource requests/limits; avoid `:latest`.  
- **Networking:** expose only required ports; restrict SGs to team IPs.  
- **Images:** immutable tags; scan with Trivy if in syllabus; later sign with cosign (optional).  
- **Backups:** re-create infra from Terraform; document restoration steps briefly.

---

## 14) Risks & Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| Underpowered EC2 / low Docker memory | Services crash/slow | Use t3.large+; start minimal set first; document limits |
| Secrets mishandled | Exposure risk | Centralize in Secrets Manager; no plaintext in repos |
| Doc drift | Onboarding breaks | Enforce Doc Tasks + DoD check; PO verification |
| Pipeline permissions | Blocked deploys | Pre-create service connections; test hello-world early |

---

## 15) Reporting & Cadence
- **Weekly PO sync (30 min):** status, blockers, milestone confidence, risk review.  
- **Sprint Review (30–45 min):** demo from current env (aim for staging/prod).  
- **Retro (20–30 min):** Keep / Start / Stop; max 3 action items.

**PO Weekly Report (template)**
- Milestone: on-track / at-risk / off-track (why)  
- Scope changes (if any)  
- Risks & asks  
- Links: latest pipeline run, environment URL, dashboards, updated docs

---

## 16) Acceptance & Sign-off (per milestone)
- All stories **Done** with Doc Evidence URL(s).  
- Demo from the target environment.  
- Product Owners confirm docs completeness; **Business Owner accepts** milestone.  
- Release notes updated (`docs/10-release-notes.md`).

---

## 17) Attachments & Templates
- **Runbook template:** `docs/templates/RUNBOOK_TEMPLATE.md`  
- **Known Issues Playbook template:** `docs/templates/PLAYBOOK_TEMPLATE.md`  
- **Postmortem template:** `docs/templates/POSTMORTEM_TEMPLATE.md`  
- **PR template:** `docs/templates/PR_TEMPLATE.md`

---

## 18) Next Steps for Product Owners
1. Ensure the platform repo is at: https://github.com/pravinmishraaws/petclinic-platform  
2. (Maintainers) Create/maintain the vendored fork: https://github.com/pravinmishraaws/petclinic-upstream (submodule target)  
3. Add the **8 Epics** and seed the **Manual Bring-Up** user stories in Taiga.  
4. Enforce “Doc Evidence URL(s)” as a required field before **Done**.  
5. Schedule the **weekly PO sync** and the **Sprint 1 Review** date.
