data "aws_availability_zones" "available" {
  state = "available" # CKV_AWS_394
}

resource "aws_vpc" "freshbox_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "freshbox-vpc" }
}

resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130: Necesario para nodos EKS sin NAT
  count                   = 2
  vpc_id                  = aws_vpc.freshbox_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_default_security_group" "default" {
  # CKV2_AWS_12: Default SG sin reglas
  vpc_id = aws_vpc.freshbox_vpc.id
}

# --- CONFIGURACIÓN PRO: Descomentar en entorno con permisos IAM ---
# resource "aws_flow_log" "vpc_flow_log" {
#   iam_role_arn    = aws_iam_role.flow_log_role.arn
#   log_destination = aws_cloudwatch_log_group.flow_log.arn
#   traffic_type    = "ALL"
#   vpc_id          = aws_vpc.freshbox_vpc.id
# }
# 
# resource "aws_cloudwatch_log_group" "flow_log" {
#   name = "freshbox-vpc-flow-logs"
# }
# 
# resource "aws_iam_role" "flow_log_role" {
#   name = "vpc-flow-log-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "vpc-flow-logs.amazonaws.com" } }]
#   })
# }


resource "aws_cloudwatch_log_group" "flow_log" {
  name = "freshbox-vpc-flow-logs"
}

resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "vpc-flow-logs.amazonaws.com" } }]
  })
}
