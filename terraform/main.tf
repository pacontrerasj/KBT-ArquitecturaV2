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
  source                = "./modules/security"
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = module.vpc.vpc_cidr_block
  eks_security_group_id = module.eks.cluster_security_group_id
}

module "ecr" {
  source = "./modules/ecr"
}

module "rds" {
  source            = "./modules/rds"
  vpc_id            = module.vpc.vpc_id
  security_group_id = module.security.db_sg_id
  subnet_ids        = module.vpc.subnet_ids
}

module "eks" {
  source     = "./modules/eks"
  subnet_ids = module.vpc.subnet_ids
}
