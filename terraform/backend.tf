terraform {
  backend "s3" {
    bucket         = "freshbox-terraform-state" # Debes crear este bucket manualmente antes
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "freshbox-terraform-lock" # Debes crear esta tabla manualmente
    encrypt        = true
  }
}
