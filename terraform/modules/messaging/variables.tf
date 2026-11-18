variable "queue_name" {
  description = "Nombre de la cola principal de órdenes"
  type        = string
  default     = "ordenes-freshbox"
}

variable "dlq_name" {
  description = "Nombre de la dead-letter queue"
  type        = string
  default     = "ordenes-freshbox-dlq"
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout de la cola principal"
  type        = number
  default     = 180
}
