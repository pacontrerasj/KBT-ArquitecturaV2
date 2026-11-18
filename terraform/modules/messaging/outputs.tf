output "queue_name" {
  value = aws_sqs_queue.ordenes.name
}

output "queue_url" {
  value = aws_sqs_queue.ordenes.url
}

output "queue_arn" {
  value = aws_sqs_queue.ordenes.arn
}

output "dlq_name" {
  value = aws_sqs_queue.dlq.name
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}
