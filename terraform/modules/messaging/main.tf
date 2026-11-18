resource "aws_sqs_queue" "dlq" {
  name                    = var.dlq_name
  sqs_managed_sse_enabled = true

  tags = {
    Name    = var.dlq_name
    Project = "freshbox"
  }
}

resource "aws_sqs_queue" "ordenes" {
  # Visibilidad >= 6x el timeout de procesar-orden (30s en FASE 3).
  name                       = var.queue_name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name    = var.queue_name
    Project = "freshbox"
  }
}
