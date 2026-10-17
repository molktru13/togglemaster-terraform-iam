variable "aws_region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "cluster_ready" {
  description = "Dependência para garantir que o Node Group do EKS esteja ativo"
  type        = string
}

variable "auth_db_address" {
  description = "Endpoint do RDS auth-db"
  type        = string
}

variable "flags_db_address" {
  description = "Endpoint do RDS flags-db"
  type        = string
}

variable "targeting_db_address" {
  description = "Endpoint do RDS targeting-db"
  type        = string
}

variable "db_username" {
  description = "Usuário do PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "master_key" {
  description = "Master Key de administração do auth-service"
  type        = string
  default     = "admin-secreto-123"
  sensitive   = true
}

variable "service_api_key" {
  description = "Chave de API interna usada pelo evaluation-service"
  type        = string
  default     = "tm_key_evaluation_service_secret"
  sensitive   = true
}

variable "redis_url" {
  description = "URL do ElastiCache Redis"
  type        = string
}

variable "sqs_queue_url" {
  description = "URL da fila SQS"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  type        = string
}

variable "evaluation_irsa_role_arn" {
  description = "ARN da IAM Role IRSA do evaluation-service"
  type        = string
}

variable "analytics_irsa_role_arn" {
  description = "ARN da IAM Role IRSA do analytics-service"
  type        = string
}

variable "keda_irsa_role_arn" {
  description = "ARN da IAM Role IRSA do KEDA Operator"
  type        = string
}
