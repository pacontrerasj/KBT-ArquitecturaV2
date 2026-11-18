provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
  vpc_name   = "freshbox-vpc"
  aws_region = "us-east-1"
}

module "security" {
  source                  = "./modules/security"
  vpc_id                  = module.vpc.vpc_id
  vpc_cidr                = module.vpc.vpc_cidr_block
  eks_security_group_id   = module.eks.cluster_security_group_id
  dynamodb_prefix_list_id = module.vpc.dynamodb_prefix_list_id
}

module "ecr" {
  source = "./modules/ecr"
}

module "rds" {
  source            = "./modules/rds"
  vpc_id            = module.vpc.vpc_id
  security_group_id = module.security.db_sg_id
  subnet_ids        = module.vpc.private_subnet_ids
  db_password       = var.db_password
  db_multi_az       = var.db_multi_az
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "messaging" {
  source = "./modules/messaging"
}

module "eks" {
  source     = "./modules/eks"
  subnet_ids = module.vpc.subnet_ids
}

module "serverless" {
  source = "./modules/serverless"

  name_prefix        = "freshbox"
  table_name         = module.dynamodb.table_name
  queue_url          = module.messaging.queue_url
  queue_arn          = module.messaging.queue_arn
  db_host            = module.rds.endpoint
  db_password        = var.db_password
  private_subnet_ids = module.vpc.private_subnet_ids
  lambda_sg_id       = module.security.lambda_sg_id
  alb_dns            = var.alb_dns
}
