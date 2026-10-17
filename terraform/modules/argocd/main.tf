locals {
  namespaces = [
    "togglemaster-auth",
    "togglemaster-flags",
    "togglemaster-targeting",
    "togglemaster-evaluation",
    "togglemaster-analytics"
  ]
}

# ==============================================================================
# 1. Namespaces Lógicos dos 5 Microsserviços
# ==============================================================================
resource "kubernetes_namespace_v1" "services" {
  for_each = toset(local.namespaces)

  metadata {
    name = each.value
    labels = {
      project    = "togglemaster"
      managed-by = "terraform"
    }
  }
}

# ==============================================================================
# 2. ServiceAccounts com IRSA (IAM Roles for Service Accounts)
# ==============================================================================
resource "kubernetes_service_account_v1" "evaluation_sa" {
  metadata {
    name      = "evaluation-sa"
    namespace = kubernetes_namespace_v1.services["togglemaster-evaluation"].metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.evaluation_irsa_role_arn
    }
  }
}

resource "kubernetes_service_account_v1" "analytics_sa" {
  metadata {
    name      = "analytics-sa"
    namespace = kubernetes_namespace_v1.services["togglemaster-analytics"].metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.analytics_irsa_role_arn
    }
  }
}

# ==============================================================================
# 3. Secrets Kubernetes injetados via Terraform (Sem texto plano no Git!)
# ==============================================================================
resource "kubernetes_secret_v1" "auth_secret" {
  metadata {
    name      = "auth-secret"
    namespace = kubernetes_namespace_v1.services["togglemaster-auth"].metadata[0].name
  }

  data = {
    DATABASE_URL = "postgres://${var.db_username}:${var.db_password}@${var.auth_db_address}:5432/auth_db?sslmode=require"
    MASTER_KEY   = var.master_key
  }

  type = "Opaque"
}

resource "kubernetes_secret_v1" "flag_secret" {
  metadata {
    name      = "flag-secret"
    namespace = kubernetes_namespace_v1.services["togglemaster-flags"].metadata[0].name
  }

  data = {
    DATABASE_URL = "postgres://${var.db_username}:${var.db_password}@${var.flags_db_address}:5432/flags_db?sslmode=require"
  }

  type = "Opaque"
}

resource "kubernetes_secret_v1" "targeting_secret" {
  metadata {
    name      = "targeting-secret"
    namespace = kubernetes_namespace_v1.services["togglemaster-targeting"].metadata[0].name
  }

  data = {
    DATABASE_URL = "postgres://${var.db_username}:${var.db_password}@${var.targeting_db_address}:5432/targeting_db?sslmode=require"
  }

  type = "Opaque"
}

resource "kubernetes_secret_v1" "evaluation_secret" {
  metadata {
    name      = "evaluation-secret"
    namespace = kubernetes_namespace_v1.services["togglemaster-evaluation"].metadata[0].name
  }

  data = {
    REDIS_URL       = var.redis_url
    SERVICE_API_KEY = var.service_api_key
    AWS_SQS_URL     = var.sqs_queue_url
    AWS_REGION      = var.aws_region
  }

  type = "Opaque"
}

resource "kubernetes_secret_v1" "analytics_secret" {
  metadata {
    name      = "analytics-secret"
    namespace = kubernetes_namespace_v1.services["togglemaster-analytics"].metadata[0].name
  }

  data = {
    AWS_SQS_URL        = var.sqs_queue_url
    AWS_DYNAMODB_TABLE = var.dynamodb_table_name
    AWS_REGION         = var.aws_region
  }

  type = "Opaque"
}

# ==============================================================================
# 4. ConfigMaps e Jobs de Migração SQL para as 3 Instâncias RDS
# ==============================================================================
resource "kubernetes_config_map_v1" "db_sql_auth" {
  metadata {
    name      = "db-sql-auth"
    namespace = kubernetes_namespace_v1.services["togglemaster-auth"].metadata[0].name
  }

  data = {
    "init.sql" = <<-EOT
      CREATE TABLE IF NOT EXISTS api_keys (
          id SERIAL PRIMARY KEY,
          name VARCHAR(100) NOT NULL,
          key_hash VARCHAR(64) NOT NULL UNIQUE,
          is_active BOOLEAN DEFAULT true,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      INSERT INTO api_keys (name, key_hash)
      VALUES ('evaluation-service-local', '7bec3ce80738989b6532134d8e6edf5e3a4b8c667eff7621158ef51d322a2833')
      ON CONFLICT (key_hash) DO NOTHING;
    EOT
  }
}

resource "kubernetes_config_map_v1" "db_sql_flags" {
  metadata {
    name      = "db-sql-flags"
    namespace = kubernetes_namespace_v1.services["togglemaster-flags"].metadata[0].name
  }

  data = {
    "init.sql" = <<-EOT
      CREATE TABLE IF NOT EXISTS flags (
          id SERIAL PRIMARY KEY,
          name VARCHAR(100) UNIQUE NOT NULL,
          description TEXT,
          is_enabled BOOLEAN NOT NULL DEFAULT false,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE OR REPLACE FUNCTION trigger_set_timestamp()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      DROP TRIGGER IF EXISTS set_timestamp ON flags;
      CREATE TRIGGER set_timestamp
      BEFORE UPDATE ON flags
      FOR EACH ROW
      EXECUTE PROCEDURE trigger_set_timestamp();
    EOT
  }
}

resource "kubernetes_config_map_v1" "db_sql_targeting" {
  metadata {
    name      = "db-sql-targeting"
    namespace = kubernetes_namespace_v1.services["togglemaster-targeting"].metadata[0].name
  }

  data = {
    "init.sql" = <<-EOT
      CREATE TABLE IF NOT EXISTS targeting_rules (
          id SERIAL PRIMARY KEY,
          flag_name VARCHAR(100) UNIQUE NOT NULL,
          is_enabled BOOLEAN NOT NULL DEFAULT true,
          rules JSONB NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE OR REPLACE FUNCTION trigger_set_timestamp()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      DROP TRIGGER IF EXISTS set_timestamp ON targeting_rules;
      CREATE TRIGGER set_timestamp
      BEFORE UPDATE ON targeting_rules
      FOR EACH ROW
      EXECUTE PROCEDURE trigger_set_timestamp();
    EOT
  }
}

resource "kubernetes_job_v1" "db_migrate_auth" {
  metadata {
    name      = "db-migrate-auth"
    namespace = kubernetes_namespace_v1.services["togglemaster-auth"].metadata[0].name
  }

  spec {
    backoff_limit = 3
    template {
      metadata {}
      spec {
        restart_policy = "Never"
        container {
          name    = "psql"
          image   = "postgres:16-alpine"
          command = ["/bin/sh", "-c"]
          args = [
            "until pg_isready -d \"$DATABASE_URL\"; do sleep 2; done && psql \"$DATABASE_URL\" -v ON_ERROR_STOP=1 -f /sql/init.sql"
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret_v1.auth_secret.metadata[0].name
            }
          }
          volume_mount {
            name       = "sql"
            mount_path = "/sql"
          }
        }
        volume {
          name = "sql"
          config_map {
            name = kubernetes_config_map_v1.db_sql_auth.metadata[0].name
          }
        }
      }
    }
  }

  wait_for_completion = true
  timeouts {
    create = "3m"
  }
}

resource "kubernetes_job_v1" "db_migrate_flags" {
  metadata {
    name      = "db-migrate-flags"
    namespace = kubernetes_namespace_v1.services["togglemaster-flags"].metadata[0].name
  }

  spec {
    backoff_limit = 3
    template {
      metadata {}
      spec {
        restart_policy = "Never"
        container {
          name    = "psql"
          image   = "postgres:16-alpine"
          command = ["/bin/sh", "-c"]
          args = [
            "until pg_isready -d \"$DATABASE_URL\"; do sleep 2; done && psql \"$DATABASE_URL\" -v ON_ERROR_STOP=1 -f /sql/init.sql"
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret_v1.flag_secret.metadata[0].name
            }
          }
          volume_mount {
            name       = "sql"
            mount_path = "/sql"
          }
        }
        volume {
          name = "sql"
          config_map {
            name = kubernetes_config_map_v1.db_sql_flags.metadata[0].name
          }
        }
      }
    }
  }

  wait_for_completion = true
  timeouts {
    create = "3m"
  }
}

resource "kubernetes_job_v1" "db_migrate_targeting" {
  metadata {
    name      = "db-migrate-targeting"
    namespace = kubernetes_namespace_v1.services["togglemaster-targeting"].metadata[0].name
  }

  spec {
    backoff_limit = 3
    template {
      metadata {}
      spec {
        restart_policy = "Never"
        container {
          name    = "psql"
          image   = "postgres:16-alpine"
          command = ["/bin/sh", "-c"]
          args = [
            "until pg_isready -d \"$DATABASE_URL\"; do sleep 2; done && psql \"$DATABASE_URL\" -v ON_ERROR_STOP=1 -f /sql/init.sql"
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret_v1.targeting_secret.metadata[0].name
            }
          }
          volume_mount {
            name       = "sql"
            mount_path = "/sql"
          }
        }
        volume {
          name = "sql"
          config_map {
            name = kubernetes_config_map_v1.db_sql_targeting.metadata[0].name
          }
        }
      }
    }
  }

  wait_for_completion = true
  timeouts {
    create = "3m"
  }
}

# ==============================================================================
# 5. Instalação do ArgoCD via Helm Provider (GitOps Controller)
# ==============================================================================
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.7.12"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  depends_on = [kubernetes_namespace_v1.services]
}

# ==============================================================================
# 6. Instalação do Ingress Nginx, Metrics Server e KEDA via Helm Provider
# ==============================================================================
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.11.3"
  namespace        = "ingress-nginx"
  create_namespace = true
  timeout          = 600

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "controller.allowSnippetAnnotations"
    value = "true"
  }

  depends_on = [helm_release.argocd]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"
  namespace  = "kube-system"
  timeout    = 300

  depends_on = [helm_release.ingress_nginx]
}

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  version          = "2.16.0"
  namespace        = "keda"
  create_namespace = true
  timeout          = 600

  set {
    name  = "serviceAccount.operator.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.keda_irsa_role_arn
  }

  depends_on = [helm_release.metrics_server]
}
