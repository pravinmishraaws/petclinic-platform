---
name: deploy-dev
description: Deploy services to the dev EKS namespace via ArgoCD (or kubectl for bootstrap)
disable-model-invocation: true
argument-hint: "[service|all]"
---

# /deploy-dev [service|all]

Deploy services to the petclinic-dev namespace.

## Arguments

- `service` — Specific service to deploy (e.g., `config-server`, `api-gateway`) or `all`
- Default: `all`

## Steps

1. Verify kubectl context is configured for the dev cluster:
   ```bash
   kubectl config current-context
   ```
   If not configured, run:
   ```bash
   aws eks update-kubeconfig --name petclinic-dev --region us-east-1
   ```

2. Check if ArgoCD is installed:
   ```bash
   kubectl get namespace argocd 2>/dev/null
   ```

3. **If ArgoCD is installed (standard path):**

   - **all**: Sync all dev ArgoCD Applications:
     ```bash
     argocd app sync -l environment=dev
     ```
   - **specific service**: Sync that service's ArgoCD Application:
     ```bash
     argocd app sync {service}-dev
     ```
   - Wait for sync to complete:
     ```bash
     argocd app wait {service}-dev --timeout 120
     ```

4. **If ArgoCD is NOT installed (bootstrap path):**

   - Apply namespace first (idempotent):
     ```bash
     kubectl apply -f k8s/base/namespaces.yaml
     ```
   - **all**: Install via Helm directly:
     ```bash
     for service in config-server discovery-server api-gateway customers-service visits-service vets-service genai-service admin-server; do
       helm upgrade --install $service helm/petclinic-service/ \
         -f helm-values/$service.yaml \
         -f helm-values/dev.yaml \
         -n petclinic-dev --create-namespace
     done
     ```
   - **specific service**: Install that service via Helm:
     ```bash
     helm upgrade --install {service} helm/petclinic-service/ \
       -f helm-values/{service}.yaml \
       -f helm-values/dev.yaml \
       -n petclinic-dev
     ```

5. For service startup order (when deploying all):
   - Deploy config-server first, wait for ready
   - Deploy discovery-server second, wait for ready
   - Deploy all remaining services

6. Monitor rollout status:
   ```bash
   kubectl rollout status deployment/{service} -n petclinic-dev --timeout=120s
   ```

7. Show final pod status:
   ```bash
   kubectl get pods -n petclinic-dev -o wide
   ```

8. If any pod fails to start, show logs:
   ```bash
   kubectl logs deployment/{failing-service} -n petclinic-dev --tail=50
   ```

## Important

- This deploys to DEV only — use `/deploy-prod` for production
- Prefer ArgoCD sync when available (standard path after E-17)
- Monitor the rollout — don't assume success without checking pod status
- If a deployment fails, show the logs and describe the issue
