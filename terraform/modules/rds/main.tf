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
  password          = "alumno123"

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
