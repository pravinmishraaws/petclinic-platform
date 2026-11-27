# Root module for dev environment
# Calls shared modules with dev-specific parameters

module "vpc" {
  source = "../../modules/vpc"

  project             = var.project
  environment         = var.environment
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones  = ["us-east-1a", "us-east-1b"]
}

module "eks" {
  source = "../../modules/eks"

  project     = var.project
  environment = var.environment

  subnet_ids                = module.vpc.public_subnet_ids
  cluster_security_group_id = module.vpc.eks_cluster_sg_id
  node_security_group_id    = module.vpc.eks_node_sg_id

  kubernetes_version = "1.35"

  endpoint_public_access_cidrs = var.api_allowed_cidrs

  node_instance_types = ["t4g.small"]
  node_min_size       = 2
  node_max_size       = 4
  node_desired_size   = 4
}

module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment

  service_names = [
    "config-server",
    "discovery-server",
    "api-gateway",
    "customers-service",
    "visits-service",
    "vets-service",
    "genai-service",
    "admin-server",
  ]

  image_tag_mutability = "MUTABLE"
}

module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.vpc.rds_sg_id

  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 20
  multi_az              = false

  backup_retention_period        = 7
  skip_final_snapshot            = true
  secret_recovery_window_in_days = 0
}

module "dns" {
  source = "../../modules/dns"

  project     = var.project
  environment = var.environment

  domain_name       = var.domain_name
  enable_dns        = var.enable_dns
  app_hostname      = "petclinic-${var.environment}"
  create_alb_record = var.create_alb_record

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

module "secrets" {
  source = "../../modules/secrets"

  project     = var.project
  environment = var.environment

  openai_api_key          = var.openai_api_key
  recovery_window_in_days = 0

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  project         = var.project
  github_username = "oriz1303prod"
  github_repo     = "spring-petclinic-microservices"
  github_owner_id = "332028694"
  github_repo_id  = "1383121042"
}
