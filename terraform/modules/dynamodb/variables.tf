variable "table_name" {
  description = "Nombre de la tabla DynamoDB del carrito"
  type        = string
  default     = "carrito-freshbox"
}

variable "ttl_attribute" {
  description = "Atributo TTL de expiración del carrito"
  type        = string
  default     = "expiresAt"
}
