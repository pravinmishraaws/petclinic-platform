# Operations Runbook

## Health checks
- Readiness: /actuator/health/readiness
- Liveness: /actuator/health/liveness

## Common operations
- Scale:
  ```bash
  kubectl -n <ns> scale deploy/<name> --replicas=N
  ```
- Rollback:
  ```bash
  kubectl -n <ns> rollout undo deploy/<name>
  ```
