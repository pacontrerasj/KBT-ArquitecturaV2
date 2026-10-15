# terraform/modules/rds/main.tf
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  db_name              = "freshboxdb"
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "password123" # Debería usar secrets manager, pero por lab esto es ok
  skip_final_snapshot  = true
  vpc_security_group_ids = [var.security_group_id]
}

variable "security_group_id" { type = string }
variable "vpc_id" { type = string }
