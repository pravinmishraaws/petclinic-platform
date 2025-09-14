# Student Guide — Petclinic Platform (AWS)
> **Read this first.** You will contribute **automation, configuration, and documentation only** in this repository.  
> The upstream Spring Petclinic app is vendored here and **must not** be modified.

---

## TL;DR — Your 8-step workflow
1. **Fork** the platform repo → **https://github.com/pravinmishraaws/petclinic-platform** → click **Fork** to your GitHub account.  
2. **Clone your fork with submodules**  
   ```bash
   git clone --recurse-submodules https://github.com/<your-username>/petclinic-platform
   cd petclinic-platform
   ```
3. **Add the canonical repo as upstream** (so you can stay in sync):
   ```bash
   git remote add upstream https://github.com/pravinmishraaws/petclinic-platform
   git remote -v
   ```
4. **Sync & branch**  
   ```bash
   git checkout main
   git pull --rebase upstream main
   git push origin main
   git checkout -b feat/k8s-deployments
   ```
5. **Work only in allowed areas** (see table below).  
6. **Commit** (Conventional Commits recommended) and **push to your fork**.  
7. **Open a Pull Request (PR)** from your fork → **upstream** `main`. Link your Taiga story.  
8. Ensure checks pass, update **docs + evidence**, request review.

> If you forgot `--recurse-submodules` when cloning:  
> ```bash
> git submodule update --init --recursive
> ```

---

## Repository you will use
- **Work in:** your **fork** of **https://github.com/pravinmishraaws/petclinic-platform**
- **Open PRs to:** **https://github.com/pravinmishraaws/petclinic-platform** (the canonical repo)
- **Do NOT modify:** `vendor/petclinic/` → vendored upstream app (read-only). Changes here are blocked by CODEOWNERS.
- **Do NOT change:** `.gitmodules` or submodule URLs.

> Need an app change? Open an issue and tag your Product Owner.

---

## Where to work (allowed areas)
| Path | Purpose | Typical tasks |
|---|---|---|
| `terraform/` | AWS infra via Terraform | Remote state (S3+DDB), VPC, EKS, ECR |
| `ansible/` | Ops VM bootstrap & hardening | Install docker/kubectl/awscli, SSH policy, idempotent roles |
| `k8s/base/` | Base Kubernetes manifests (plain YAML) | Deployments, Services, ServiceAccounts, ConfigMaps, Secrets (ref AWS Secrets Manager) |
| `k8s/envs/dev|staging|prod/` | Env-specific overlays | Image tags, replica counts, env vars, service type/ingress |
| `pipelines/azure-devops/` | Multi-stage pipelines | Build → push to ECR → `kubectl apply` to EKS |
| `docs/` | Documentation & evidence | Runbook, Playbook, Architecture, Onboarding, Release Notes, screenshots in `docs/img/` |
| `vendor/petclinic/` | **Vendored upstream app** | _Do not change_. Maintainers bump this pointer when syncing upstream |

---

## Staying in sync with upstream (keep your fork fresh)
Before starting any work (and periodically), synchronize your fork:
```bash
git checkout main
git fetch upstream
git rebase upstream/main         # or: git merge upstream/main
git push origin main
```
Resolve conflicts locally if needed. **Never** modify `vendor/petclinic/` to resolve conflicts—ask maintainers if the submodule pointer changed.

If submodules look empty/outdated:
```bash
git submodule update --init --recursive
```

---

## Branching & Pull Requests
1. **Create a feature branch** from updated `main`:
   ```bash
   git checkout -b feat/<area>-<short-desc>
   # e.g., feat/k8s-gateway, fix/terraform-backend, docs/runbook-restart
   ```
2. **Commit style (recommended)**: Conventional Commits  
   - `feat(k8s): add deployment and service for api-gateway`  
   - `docs(runbook): add restart/rollback steps`  
3. **Push to your fork** and open a **PR to upstream `main`**.  
4. **Fill the PR template**: link the Taiga story, describe what changed, **attach evidence** (URLs/screens).  
5. **Fix checks** (pipeline, linters) and respond to reviews.

**Auto-blocks:** PRs that touch `vendor/petclinic/**` or `.gitmodules` will be rejected by CODEOWNERS.

---

## Required evidence for acceptance
Include links/screenshots in your PR **and** update relevant `docs/` pages:
- Azure DevOps pipeline run URL (`Build`, `Deploy` stages)  
- Environment endpoint(s) (dev/staging/prod) used to verify behavior  
- Grafana dashboards / Prometheus queries (if relevant)  
- `kubectl` output for deployed objects, e.g.:
  ```bash
  kubectl -n app-dev get deploy,svc,pods
  ```
- Terraform plan/apply snippets for infra changes

> Store images in `docs/img/` and link them from the relevant `.md` page.

---

## Local validation (lightweight)
- **K8s YAML:**  
  ```bash
  kubectl apply --dry-run=client -f k8s/base/
  ```
- **Terraform (format & validate):**
  ```bash
  terraform fmt -recursive
  terraform validate
  ```
- **Ansible (syntax check):**
  ```bash
  ansible-playbook playbook.yml --syntax-check
  ```
- **YAML sanity:** use your editor’s YAML linter.

> Building and pushing images is handled by CI; you don’t need Docker locally unless your story requires it.

---

## Common gotchas & fixes
- **Submodules missing/outdated:** `git submodule update --init --recursive`  
- **ECR/EKS access denied:** request correct IAM/service connection via mentors  
- **Pods not ready:** check logs (`kubectl logs`), verify image tag, readiness/liveness probes  
- **Secrets:** Never commit secrets. Use AWS Secrets Manager; reference with env vars in manifests/pipeline  
- **Merge conflicts:** rebase your branch on `upstream/main`; if submodule pointer conflicts, ping a maintainer

---

## Support
- Taiga board: _<link>_  
- Discussion (Slack/Teams): _<link>_  
- Maintainers: _<@PO-1>_, _<@PO-2>_, _<@Dev Lead>_

---

## Attribution
This coursework vendors the **spring-petclinic-microservices** app for educational deployment/operations.  
Original project: https://github.com/spring-petclinic/spring-petclinic-microservices
