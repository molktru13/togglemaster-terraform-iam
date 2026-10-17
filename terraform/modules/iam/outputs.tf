output "cluster_role_arn" {
  description = "ARN da IAM Role do Cluster EKS"
  value       = aws_iam_role.eks_cluster.arn
}

output "node_role_arn" {
  description = "ARN da IAM Role do Node Group do EKS"
  value       = aws_iam_role.eks_nodes.arn
}

output "evaluation_irsa_role_arn" {
  description = "ARN da IAM Role IRSA do evaluation-service"
  value       = aws_iam_role.evaluation_irsa.arn
}

output "analytics_irsa_role_arn" {
  description = "ARN da IAM Role IRSA do analytics-service"
  value       = aws_iam_role.analytics_irsa.arn
}

output "keda_irsa_role_arn" {
  description = "ARN da IAM Role IRSA do KEDA Operator"
  value       = aws_iam_role.keda_irsa.arn
}
