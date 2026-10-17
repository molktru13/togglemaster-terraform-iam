output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR da VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "rds_security_group_id" {
  description = "ID do Security Group do RDS"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "ID do Security Group do Redis"
  value       = aws_security_group.redis.id
}
