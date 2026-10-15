terraform {
  backend "s3" {
    key     = "prod/terraform.tfstate"
    encrypt = true
    # bucket, region y dynamodb_table se inyectan desde GitHub Actions
    # vía -backend-config (ver .github/workflows/pipeline.yaml).
    # Para uso local: terraform init -backend-config="bucket=..." -backend-config="dynamodb_table=..." -backend-config="region=us-east-1"
  }
}
