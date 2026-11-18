data "aws_availability_zones" "available" {
  # checkov:skip=CKV_AWS_394: Check sin impacto de seguridad en el Learner Lab
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_vpc" "freshbox_vpc" {
  # checkov:skip=CKV2_AWS_11: El Learner Lab no permite crear el destino de VPC Flow Logs (SCP deniega S3/IAM)
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.vpc_name }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.freshbox_vpc.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130: Necesario para nodos EKS sin NAT
  count                   = 2
  vpc_id                  = aws_vpc.freshbox_vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.vpc_name}-public-${count.index}" }
}

resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.freshbox_vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index + 10)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.vpc_name}-private-${count.index}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.freshbox_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "${var.vpc_name}-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.freshbox_vpc.id
  tags   = { Name = "${var.vpc_name}-private-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.freshbox_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "${var.vpc_name}-dynamodb-endpoint" }
}

resource "aws_default_security_group" "default" {
  # CKV2_AWS_12: Default SG sin reglas
  vpc_id = aws_vpc.freshbox_vpc.id
}

# NOTA: VPC Flow Logs deshabilitado a propósito. La SCP del AWS Academy
# Learner Lab deniega s3:GetBucketObjectLockConfiguration, por lo que el
# provider AWS no puede leer NINGÚN aws_s3_bucket (falla en el refresh).
# Tampoco se puede crear el rol IAM que requiere CloudWatch Logs como destino.
