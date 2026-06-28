# Remote state backend — prod environment
# Spec: docs/technical-spec.md#terraform-state-backend
#
# Same S3 bucket and DynamoDB lock table as dev; only the state key differs.
# The bucket name includes the AWS account ID (pattern:
# petclinic-terraform-state-{account-id}), which cannot be interpolated inside
# a backend block. Replace ACCOUNT_ID below, or supply it at init time:
#
#   terraform init -backend-config="bucket=petclinic-terraform-state-123456789012"
#
terraform {
  backend "s3" {
    bucket         = "petclinic-terraform-state-512634244263"
    key            = "petclinic/prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "petclinic-terraform-locks"
    encrypt        = true
  }
}
