variable "table_name" {
  description = "Nome da tabela DynamoDB"
  type        = string
  default     = "ToggleMasterAnalytics"
}

resource "aws_dynamodb_table" "analytics" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name    = var.table_name
    Service = "analytics-service"
  }
}

output "table_name" {
  description = "Nome da tabela DynamoDB"
  value       = aws_dynamodb_table.analytics.name
}

output "table_arn" {
  description = "ARN da tabela DynamoDB"
  value       = aws_dynamodb_table.analytics.arn
}
