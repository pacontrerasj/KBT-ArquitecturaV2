output "vpc_id" {
  value = aws_vpc.freshbox_vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.freshbox_vpc.cidr_block
}

output "subnet_ids" {
  description = "Subnets públicas (compatibilidad con EP2)"
  value       = aws_subnet.public[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "dynamodb_vpc_endpoint_id" {
  value = aws_vpc_endpoint.dynamodb.id
}
