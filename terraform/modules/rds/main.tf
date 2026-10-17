locals {
  databases = {
    auth = {
      identifier = "${var.project_name}-auth-db"
      db_name    = "auth_db"
    }
    flags = {
      identifier = "${var.project_name}-flags-db"
      db_name    = "flags_db"
    }
    targeting = {
      identifier = "${var.project_name}-targeting-db"
      db_name    = "targeting_db"
    }
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# 3 Instâncias RDS PostgreSQL independentes (Database-per-Service)
resource "aws_db_instance" "postgres" {
  for_each = local.databases

  identifier             = each.value.identifier
  engine                 = "postgres"
  instance_class         = var.instance_class
  allocated_storage      = 20
  storage_type           = "gp3"
  storage_encrypted      = true
  db_name                = each.value.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = {
    Name    = each.value.identifier
    Service = "${each.key}-service"
  }
}

# Armazena as credenciais de forma segura no AWS Secrets Manager
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.project_name}/rds/credentials"
  description             = "Credenciais e endpoints das 3 instancias RDS PostgreSQL do ToggleMaster"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username               = var.db_username
    password               = var.db_password
    auth_db_endpoint       = aws_db_instance.postgres["auth"].address
    flags_db_endpoint      = aws_db_instance.postgres["flags"].address
    targeting_db_endpoint  = aws_db_instance.postgres["targeting"].address
    auth_database_url      = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["auth"].address}:5432/auth_db?sslmode=require"
    flags_database_url     = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["flags"].address}:5432/flags_db?sslmode=require"
    targeting_database_url = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["targeting"].address}:5432/targeting_db?sslmode=require"
  })
}
