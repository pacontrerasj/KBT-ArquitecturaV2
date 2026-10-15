variable "cidr_block" {
  description = "CIDR block para la VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Nombre de la VPC"
  default     = "freshbox-vpc"
}
