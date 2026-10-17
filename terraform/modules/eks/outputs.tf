output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint do API Server do EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Certificado CA (base64) do cluster EKS"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security Group gerenciado pelo EKS"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "node_group_status" {
  description = "Status do Node Group"
  value       = aws_eks_node_group.main.status
}

output "oidc_provider_arn" {
  description = "ARN do OIDC Provider do EKS"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL do OIDC Provider sem https://"
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}
