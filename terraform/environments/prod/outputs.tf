# Outputs — prod environment
# Spec: docs/technical-spec.md
#
# Module outputs (vpc_id, cluster_endpoint, repository_urls, rds endpoint, etc.)
# are exported here as modules are wired in later epics.

output "environment" {
  description = "Environment name."
  value       = var.environment
}

output "aws_region" {
  description = "AWS region for this environment."
  value       = var.aws_region
}
