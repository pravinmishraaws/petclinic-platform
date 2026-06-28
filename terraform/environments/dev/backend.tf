# Remote state backend — dev environment
# Spec: docs/technical-spec.md#terraform-state-backend
#
# The S3 bucket and DynamoDB table are created by scripts/bootstrap-state.sh
# BEFORE the first `terraform init`. The bucket name includes the AWS account
# ID (pattern: petclinic-terraform-state-{account-id}), which cannot be
# interpolated inside a backend block. Replace ACCOUNT_ID below, or supply it
# at init time without editing this file:
#
#   terraform init -backend-config="bucket=petclinic-terraform-state-123456789012"
#
terraform {
  backend "s3" {
    bucket         = "petclinic-terraform-state-512634244263"
    key            = "petclinic/dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "petclinic-terraform-locks"
    encrypt        = true
  }
}
