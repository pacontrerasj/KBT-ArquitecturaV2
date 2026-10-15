provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "./modules/vpc"
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}

module "ecr" {
  source = "./modules/ecr"
}

module "rds" {
  source            = "./modules/rds"
  vpc_id            = module.vpc.vpc_id
  security_group_id = module.security.db_sg_id
}

module "eks" {
  source     = "./modules/eks"
  subnet_ids = module.vpc.subnet_ids
}
