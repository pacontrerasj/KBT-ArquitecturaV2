variable "name_prefix" {
  description = "Prefijo de nombres para Lambdas y API Gateway"
  type        = string
  default     = "freshbox"
}

variable "table_name" {
  description = "Tabla DynamoDB del carrito"
  type        = string
}

variable "queue_url" {
  description = "URL de la cola SQS de ordenes"
  type        = string
}

variable "queue_arn" {
  description = "ARN de la cola SQS de ordenes"
  type        = string
}

variable "db_host" {
  description = "Endpoint privado de RDS"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos MySQL"
  type        = string
  default     = "freshbox"
}

variable "db_user" {
  description = "Usuario de MySQL"
  type        = string
  default     = "alumno"
}

variable "db_password" {
  description = "Password de MySQL inyectada por el pipeline"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Puerto de MySQL"
  type        = number
  default     = 3306
}

variable "private_subnet_ids" {
  description = "Subnets privadas para la Lambda Process-Order"
  type        = list(string)
}

variable "lambda_sg_id" {
  description = "Security group de las Lambdas dentro de la VPC"
  type        = string
}

variable "alb_dns" {
  description = "DNS del ALB creado por el Ingress. Vacio en el primer apply."
  type        = string
  default     = ""
}

variable "lambda_role_arn" {
  description = "ARN de rol para Lambdas. Vacio usa LabRole por restriccion del Learner Lab."
  type        = string
  default     = ""
}
