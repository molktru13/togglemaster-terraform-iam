variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "togglemaster"
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas para o Subnet Group do RDS"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID do Security Group do RDS"
  type        = string
}

variable "db_username" {
  description = "Usuário master do PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha master do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}
