output "auth_db_address" {
  description = "Hostname da instância RDS auth-db"
  value       = aws_db_instance.postgres["auth"].address
}

output "flags_db_address" {
  description = "Hostname da instância RDS flags-db"
  value       = aws_db_instance.postgres["flags"].address
}

output "targeting_db_address" {
  description = "Hostname da instância RDS targeting-db"
  value       = aws_db_instance.postgres["targeting"].address
}

output "rds_endpoints" {
  description = "Mapa com os endpoints das 3 instâncias RDS"
  value = {
    for k, v in aws_db_instance.postgres : k => v.endpoint
  }
}

output "secrets_manager_arn" {
  description = "ARN do segredo no AWS Secrets Manager"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}
