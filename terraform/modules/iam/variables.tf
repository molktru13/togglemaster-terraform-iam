variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "togglemaster"
}

variable "oidc_provider_arn" {
  description = "ARN do OIDC Provider do cluster EKS para IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL do OIDC Provider do cluster EKS (sem https://)"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN da fila SQS do ToggleMaster"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN da tabela DynamoDB do ToggleMaster"
  type        = string
}
