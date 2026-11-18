output "rds_endpoint" {
  value = module.rds.endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "private_route_table_id" {
  value = module.vpc.private_route_table_id
}

output "dynamodb_vpc_endpoint_id" {
  value = module.vpc.dynamodb_vpc_endpoint_id
}

output "db_sg_id" {
  value = module.security.db_sg_id
}

output "lambda_sg_id" {
  value = module.security.lambda_sg_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  value = module.dynamodb.table_arn
}

output "sqs_queue_name" {
  value = module.messaging.queue_name
}

output "sqs_queue_url" {
  value = module.messaging.queue_url
}

output "sqs_queue_arn" {
  value = module.messaging.queue_arn
}

output "sqs_dlq_name" {
  value = module.messaging.dlq_name
}

output "sqs_dlq_url" {
  value = module.messaging.dlq_url
}

output "sqs_dlq_arn" {
  value = module.messaging.dlq_arn
}
