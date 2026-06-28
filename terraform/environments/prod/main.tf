# Root module — prod environment
# Spec: docs/technical-spec.md
#
# Module calls (VPC, EKS, ECR, RDS, DNS, Secrets, Observability) are wired in
# their respective epics (E-2 onward). This file currently establishes the
# common locals used across module calls.

locals {
  name_prefix = "${var.project}-${var.environment}"

  # Common tags merged into each module's `tags` input. The same three tags are
  # also applied globally via the provider's default_tags (see providers.tf).
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
