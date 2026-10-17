variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "togglemaster"
}

variable "cluster_name" {
  description = "Nome do cluster EKS para tags de descoberta de subnets"
  type        = string
  default     = "toggle-master-cluster"
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}
