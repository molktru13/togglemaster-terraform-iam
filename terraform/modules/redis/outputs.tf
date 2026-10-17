output "redis_endpoint" {
  description = "Hostname do nó primário do Redis"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "redis_port" {
  description = "Porta do Redis"
  value       = aws_elasticache_cluster.main.cache_nodes[0].port
}

output "redis_url" {
  description = "URL de conexão do Redis"
  value       = "redis://${aws_elasticache_cluster.main.cache_nodes[0].address}:${aws_elasticache_cluster.main.cache_nodes[0].port}"
}
