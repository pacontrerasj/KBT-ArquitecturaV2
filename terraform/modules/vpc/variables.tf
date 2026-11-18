variable "cidr_block" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Nombre de la VPC"
  type        = string
  default     = "freshbox-vpc"
}

variable "aws_region" {
  description = "Región AWS usada por el endpoint Gateway de DynamoDB"
  type        = string
  default     = "us-east-1"
}
