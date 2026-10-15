resource "aws_security_group" "db_sg" {
  # checkov:skip=CKV2_AWS_5: SG usado exclusivamente por el módulo RDS
  name        = "db-sg"
  description = "Security group para base de datos RDS" # CKV_AWS_23
  vpc_id      = var.vpc_id
  ingress {
    description = "Acceso MySQL desde la VPC" # CKV_AWS_23
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

output "db_sg_id" { value = aws_security_group.db_sg.id }
variable "vpc_id" { type = string }
