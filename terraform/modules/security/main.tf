resource "aws_security_group" "db_sg" {
  # checkov:skip=CKV2_AWS_5: SG usado exclusivamente por el módulo RDS
  name        = "db-sg"
  description = "Security group para base de datos RDS" # CKV_AWS_23
  vpc_id      = var.vpc_id
  tags        = { Name = "freshbox-db-sg" }
}

resource "aws_security_group" "lambda_sg" {
  # checkov:skip=CKV2_AWS_5: SG usado por las Lambdas del módulo lambdas (FASE 3)
  name        = "lambda-sg"
  description = "Security group para funciones Lambda dentro de la VPC"
  vpc_id      = var.vpc_id
  tags        = { Name = "freshbox-lambda-sg" }
}

resource "aws_security_group_rule" "db_from_eks" {
  description              = "MySQL desde los nodos EKS"
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = var.eks_security_group_id
}

resource "aws_security_group_rule" "db_from_lambda" {
  description              = "MySQL desde las funciones Lambda"
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_to_rds" {
  description              = "MySQL hacia RDS"
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_sg.id
  source_security_group_id = aws_security_group.db_sg.id
}

resource "aws_security_group_rule" "lambda_dns_udp" {
  description       = "DNS de la VPC (UDP)"
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.lambda_sg.id
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "lambda_dns_tcp" {
  description       = "DNS de la VPC (TCP)"
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_sg.id
  cidr_blocks       = [var.vpc_cidr]
}

output "db_sg_id" { value = aws_security_group.db_sg.id }
output "lambda_sg_id" { value = aws_security_group.lambda_sg.id }

variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "eks_security_group_id" { type = string }
