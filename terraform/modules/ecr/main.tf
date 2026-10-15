resource "aws_ecr_repository" "repo" {
  for_each             = toset(["get-products", "create-product", "update-product", "delete-product", "frontend"])
  name                 = "freshbox-${each.key}"
  image_tag_mutability = "IMMUTABLE" # Hardening

  encryption_configuration {
    encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
