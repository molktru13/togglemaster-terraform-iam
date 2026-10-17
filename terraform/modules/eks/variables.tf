variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
  default     = "toggle-master-cluster"
}

variable "cluster_version" {
  description = "Versão do Kubernetes no EKS"
  type        = string
  default     = "1.31"
}

variable "cluster_role_arn" {
  description = "ARN da IAM Role do Cluster EKS"
  type        = string
}

variable "node_role_arn" {
  description = "ARN da IAM Role dos Worker Nodes"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets para o Control Plane do EKS"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas para o Node Group"
  type        = list(string)
}

variable "node_instance_types" {
  description = "Tipos de instância EC2 do Node Group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "desired_size" {
  description = "Quantidade desejada de nós"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Quantidade mínima de nós"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Quantidade máxima de nós"
  type        = number
  default     = 5
}
