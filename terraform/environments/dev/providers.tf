# AWS provider configuration — dev environment
# Common tags are applied to every resource via default_tags.
# Spec: docs/technical-spec.md#required-tags-all-aws-resources

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
