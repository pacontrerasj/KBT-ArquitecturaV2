terraform {
  backend "s3" {
    key     = "prod/terraform.tfstate"
    encrypt = true
    # bucket y region se inyectan desde GitHub Actions vía -backend-config
    # (ver .github/workflows/pipeline.yaml).
    # SIN bloqueo DynamoDB a propósito: un run que muere (p. ej. token del
    # Learner Lab expirado) deja el lock colgado y bloquea todos los runs
    # siguientes. La exclusión mutua la garantiza el `concurrency` de Actions.
    # Para uso local: terraform init -backend-config="bucket=..." -backend-config="region=us-east-1"
  }
}
