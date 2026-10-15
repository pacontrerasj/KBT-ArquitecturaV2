# terraform/modules/vpc/main.tf
resource "aws_vpc" "freshbox_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "freshbox-vpc" }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.freshbox_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

data "aws_availability_zones" "available" {}

output "vpc_id" { value = aws_vpc.freshbox_vpc.id }
output "subnet_ids" { value = aws_subnet.public[*].id }
