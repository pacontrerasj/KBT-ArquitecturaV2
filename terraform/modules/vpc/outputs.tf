output "vpc_id" {
  value = aws_vpc.freshbox_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}
