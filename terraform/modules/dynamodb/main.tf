resource "aws_dynamodb_table" "carrito" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "productId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "productId"
    type = "S"
  }

  ttl {
    attribute_name = var.ttl_attribute
    enabled        = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name    = var.table_name
    Project = "freshbox"
  }
}
