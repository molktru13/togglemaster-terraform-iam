output "argocd_namespace" {
  description = "Namespace do ArgoCD"
  value       = helm_release.argocd.namespace
}

output "argocd_release_status" {
  description = "Status do release Helm do ArgoCD"
  value       = helm_release.argocd.status
}

output "ingress_nginx_status" {
  description = "Status do release Helm do Ingress Nginx"
  value       = helm_release.ingress_nginx.status
}

output "keda_status" {
  description = "Status do release Helm do KEDA"
  value       = helm_release.keda.status
}
