provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ToggleMaster"
      Environment = "production"
      Phase       = "Fase-03"
      Turma       = "4DCLT"
      ManagedBy   = "Terraform"
      Author      = "Marcilio-Alves-Galindo-RM374871"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
  }
}

provider "helm" {
  repository_config_path = "C:/FIAP/.helm/repositories.yaml"
  repository_cache       = "C:/FIAP/.helm/cache"

  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
    }
  }
}
