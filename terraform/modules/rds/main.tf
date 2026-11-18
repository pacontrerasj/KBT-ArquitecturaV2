resource "aws_db_subnet_group" "default" {
  name       = "freshbox-db-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = { Name = "freshbox-db-subnet-group" }
}

resource "aws_db_instance" "default" {
  # checkov:skip=CKV_AWS_157: Costo en laboratorio
  # checkov:skip=CKV_AWS_118: Costo en laboratorio
  allocated_storage = 20
  db_name           = "freshbox"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  username          = "alumno"
  password          = var.db_password
  multi_az          = var.db_multi_az
  storage_type      = "gp2" # Learner Lab solo permite gp2

  db_subnet_group_name   = aws_db_subnet_group.default.name
  storage_encrypted      = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [var.security_group_id]

  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports     = ["error", "general", "slowquery"]
  deletion_protection                 = true
}

variable "security_group_id" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }

variable "db_password" {
  description = "Password de RDS MySQL inyectada con TF_VAR_db_password"
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Multi-AZ no soportado en Learner Lab; true en producción"
  type        = bool
  default     = false
}
