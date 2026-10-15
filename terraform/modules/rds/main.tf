resource "aws_db_instance" "default" {
  allocated_storage           = 20
  db_name                     = "freshboxdb"
  engine                      = "mysql"
  instance_class              = "db.t3.micro"
  username                    = "admin"
  manage_master_user_password = true # Hardening

  storage_encrypted      = true # Fuerza reemplazo
  skip_final_snapshot    = true
  vpc_security_group_ids = [var.security_group_id]

  # Mejoras solicitadas
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports     = ["error", "general", "slowquery"]
  deletion_protection                 = true

  # checkov:skip=CKV_AWS_157: Costo en laboratorio
  # checkov:skip=CKV_AWS_118: Costo en laboratorio
}

variable "security_group_id" { type = string }
variable "vpc_id" { type = string }
