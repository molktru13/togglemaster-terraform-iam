variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "togglemaster"
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas para o ElastiCache"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID do Security Group do Redis"
  type        = string
}

variable "node_type" {
  description = "Tipo do nó ElastiCache"
  type        = string
  default     = "cache.t3.micro"
}
