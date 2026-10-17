# ==============================================================================
# Tech Challenge — Fase 03 | ToggleMaster — Terraform & IAM (Opção B: Conta Pessoal)
# Orquestração Modular de toda a Infraestrutura AWS + Kubernetes + ArgoCD
# ==============================================================================

# 1. Módulo de Networking (VPC, Subnets Públicas/Privadas, IGW, NAT, Route Tables, SGs)
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  cluster_name = var.cluster_name
}

# 2. Módulo de Repositórios de Containers (5 Repositórios no Amazon ECR)
module "ecr" {
  source = "./modules/ecr"
}

# 3. Módulo de Mensageria (1 Fila Amazon SQS)
module "sqs" {
  source = "./modules/sqs"
}

# 4. Módulo NoSQL (1 Tabela Amazon DynamoDB: ToggleMasterAnalytics)
module "dynamodb" {
  source = "./modules/dynamodb"
}

# 5. Módulo de IAM & IRSA (Opção B: Conta Pessoal — Criação completa de Roles e Policies)
module "iam" {
  source             = "./modules/iam"
  project_name       = var.project_name
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
  sqs_queue_arn      = module.sqs.queue_arn
  dynamodb_table_arn = module.dynamodb.table_arn
}

# 6. Módulo de Orquestração Kubernetes (Cluster Amazon EKS + Node Group Gerenciado)
module "eks" {
  source             = "./modules/eks"
  cluster_name       = var.cluster_name
  cluster_role_arn   = module.iam.cluster_role_arn
  node_role_arn      = module.iam.node_role_arn
  subnet_ids         = concat(module.networking.public_subnet_ids, module.networking.private_subnet_ids)
  private_subnet_ids = module.networking.private_subnet_ids
}

# 7. Módulo de Bancos Relacionais (3 Instâncias Amazon RDS PostgreSQL + Secrets Manager)
module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.networking.rds_security_group_id
  db_username        = var.db_username
  db_password        = var.db_password
}

# 8. Módulo de Cache In-Memory (1 Cluster Amazon ElastiCache Redis)
module "redis" {
  source             = "./modules/redis"
  project_name       = var.project_name
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.networking.redis_security_group_id
}

# 9. Módulo de GitOps & Add-ons (ArgoCD, Ingress Nginx, KEDA, Metrics Server, Secrets K8s)
module "argocd" {
  source                   = "./modules/argocd"
  aws_region               = var.aws_region
  cluster_ready            = module.eks.node_group_status
  auth_db_address          = module.rds.auth_db_address
  flags_db_address         = module.rds.flags_db_address
  targeting_db_address     = module.rds.targeting_db_address
  db_username              = var.db_username
  db_password              = var.db_password
  master_key               = var.master_key
  service_api_key          = var.service_api_key
  redis_url                = module.redis.redis_url
  sqs_queue_url            = module.sqs.queue_url
  dynamodb_table_name      = module.dynamodb.table_name
  evaluation_irsa_role_arn = module.iam.evaluation_irsa_role_arn
  analytics_irsa_role_arn  = module.iam.analytics_irsa_role_arn
  keda_irsa_role_arn       = module.iam.keda_irsa_role_arn
}
