# Known Issues Playbook

## Gateway 502 / timeouts right after start
- Wait for Eureka registration (~30–60s)
- Check Eureka UI at :8761

## Pods not ready
- `kubectl describe pod/<pod>`
- `kubectl logs <pod>`
