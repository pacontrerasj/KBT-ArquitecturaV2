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
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "freshbox-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.freshbox_vpc.id
  tags   = { Name = "freshbox-igw" }
}

resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130: Necesario para nodos EKS sin NAT
  count                   = 2
  vpc_id                  = aws_vpc.freshbox_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "freshbox-public-${count.index}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.freshbox_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "freshbox-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_default_security_group" "default" {
  # CKV2_AWS_12: Default SG sin reglas
  vpc_id = aws_vpc.freshbox_vpc.id
}

# NOTA: VPC Flow Logs deshabilitado a propósito. La SCP del AWS Academy
# Learner Lab deniega s3:GetBucketObjectLockConfiguration, por lo que el
# provider AWS no puede leer NINGÚN aws_s3_bucket (falla en el refresh).
# Tampoco se puede crear el rol IAM que requiere CloudWatch Logs como destino.
