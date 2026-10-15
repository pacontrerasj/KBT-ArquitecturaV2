# terraform/modules/security/main.tf
resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

output "db_sg_id" { value = aws_security_group.db_sg.id }
variable "vpc_id" { type = string }
