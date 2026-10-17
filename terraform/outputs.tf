output "vpc_id" {
  description = "ID da VPC criada pelo Terraform"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs das Subnets Públicas"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das Subnets Privadas"
  value       = module.networking.private_subnet_ids
}

output "eks_cluster_name" {
  description = "Nome do Cluster Amazon EKS"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint do Control Plane do EKS"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  description = "URLs dos 5 repositórios no Amazon ECR"
  value       = module.ecr.repository_urls
}

output "rds_endpoints" {
  description = "Endpoints das 3 instâncias RDS PostgreSQL"
  value       = module.rds.rds_endpoints
}

output "rds_secrets_manager_arn" {
  description = "ARN do segredo no AWS Secrets Manager com as credenciais do RDS"
  value       = module.rds.secrets_manager_arn
}

output "redis_url" {
  description = "URL do cluster ElastiCache Redis"
  value       = module.redis.redis_url
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  value       = module.dynamodb.table_name
}

output "sqs_queue_url" {
  description = "URL da fila Amazon SQS"
  value       = module.sqs.queue_url
}

output "iam_roles" {
  description = "ARNs das IAM Roles criadas via Terraform (Opção B: Conta Pessoal)"
  value = {
    eks_cluster_role     = module.iam.cluster_role_arn
    eks_node_role        = module.iam.node_role_arn
    evaluation_irsa_role = module.iam.evaluation_irsa_role_arn
    analytics_irsa_role  = module.iam.analytics_irsa_role_arn
    keda_irsa_role       = module.iam.keda_irsa_role_arn
  }
}

output "argocd_status" {
  description = "Status do ArgoCD instalado via Helm/Terraform"
  value       = module.argocd.argocd_release_status
}
