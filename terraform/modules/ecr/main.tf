variable "repositories" {
  description = "Lista dos 5 repositórios ECR dos microsserviços"
  type        = list(string)
  default = [
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service"
  ]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(var.repositories)

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = each.value
    Service = each.value
  }
}

resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Manter as ultimas 15 imagens para historico de rollback GitOps"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 15
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

output "repository_urls" {
  description = "Mapa com as URLs dos 5 repositórios ECR"
  value = {
    for k, v in aws_ecr_repository.services : k => v.repository_url
  }
}
