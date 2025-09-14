# Architecture

## Context
Microservices application (API Gateway, Config, Discovery, Customers, Vets, Visits).

## Deployment
- AWS EKS with namespaces: app-dev, app-staging, app-prod
- ECR for images
- Secrets via AWS Secrets Manager (referenced in pipelines/manifests)
