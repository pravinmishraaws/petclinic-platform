# Terraform

- Remote state: S3 (+ DynamoDB for locking)
- Modules: VPC, EKS, ECR (to be added)
- Region: set via `var.aws_region` (default `eu-central-1`)

## Init
```bash
terraform init
terraform validate
```

## Plan & Apply
```bash
terraform plan -out plan.out
terraform apply plan.out
```
