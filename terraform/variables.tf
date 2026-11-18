variable "db_password" {
  description = "Password de RDS MySQL. Se inyecta desde GitHub Secrets como TF_VAR_db_password"
  type        = string
  sensitive   = true
}
