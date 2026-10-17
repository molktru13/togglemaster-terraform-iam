variable "queue_name" {
  description = "Nome da fila SQS"
  type        = string
  default     = "toggle-master-events"
}

resource "aws_sqs_queue" "events" {
  name                       = var.queue_name
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true

  tags = {
    Name    = var.queue_name
    Service = "evaluation-and-analytics"
  }
}

output "queue_url" {
  description = "URL da fila SQS"
  value       = aws_sqs_queue.events.id
}

output "queue_arn" {
  description = "ARN da fila SQS"
  value       = aws_sqs_queue.events.arn
}

output "queue_name" {
  description = "Nome da fila SQS"
  value       = aws_sqs_queue.events.name
}
