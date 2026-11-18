variable "db_password" {
  description = "Password de RDS MySQL. Se inyecta desde GitHub Secrets como TF_VAR_db_password"
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.db_password) >= 8 &&
      length(var.db_password) <= 41 &&
      can(regex("^[^/\"@ ]+$", var.db_password))
    )
    error_message = "DB_PASSWORD debe tener entre 8 y 41 caracteres y no contener /, \", @ ni espacios."
  }
}

variable "db_multi_az" {
  description = "RDS Multi-AZ. false en Learner Lab (no soportado); true en producción"
  type        = bool
  default     = false
}

variable "alb_dns" {
  description = "DNS del ALB de EKS. Se inyecta en el segundo apply del pipeline."
  type        = string
  default     = ""
}
