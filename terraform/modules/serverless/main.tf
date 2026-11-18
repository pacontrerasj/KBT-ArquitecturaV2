data "aws_region" "current" {}

# El Learner Lab restringe iam:CreateRole. Se usa LabRole para las Lambdas y se
# deja lambda_role_arn para inyectar roles por funcion en un entorno real.
data "aws_iam_role" "lab" {
  name = "LabRole"
}

locals {
  lambda_role_arn = var.lambda_role_arn != "" ? var.lambda_role_arn : data.aws_iam_role.lab.arn
  alb_host        = var.alb_dns != "" ? var.alb_dns : "placeholder.local"
}

data "archive_file" "cart" {
  type        = "zip"
  source_dir  = "${path.module}/../../../Freshbox/lambdas/procesar-carrito"
  output_path = "${path.module}/../../../build/lambdas/procesar-carrito.zip"
}

data "archive_file" "create_order" {
  type        = "zip"
  source_dir  = "${path.module}/../../../Freshbox/lambdas/crear-orden"
  output_path = "${path.module}/../../../build/lambdas/crear-orden.zip"
}

data "archive_file" "process_order" {
  type        = "zip"
  source_dir  = "${path.module}/../../../Freshbox/lambdas/procesar-orden"
  output_path = "${path.module}/../../../build/lambdas/procesar-orden.zip"
}

resource "aws_lambda_function" "cart" {
  function_name    = "${var.name_prefix}-procesar-carrito"
  role             = local.lambda_role_arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.cart.output_path
  source_code_hash = data.archive_file.cart.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
}

resource "aws_lambda_function" "create_order" {
  function_name    = "${var.name_prefix}-crear-orden"
  role             = local.lambda_role_arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.create_order.output_path
  source_code_hash = data.archive_file.create_order.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME = var.table_name
      QUEUE_URL  = var.queue_url
    }
  }
}

resource "aws_lambda_function" "process_order" {
  function_name    = "${var.name_prefix}-procesar-orden"
  role             = local.lambda_role_arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.process_order.output_path
  source_code_hash = data.archive_file.process_order.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME = var.table_name
      DB_HOST    = var.db_host
      DB_NAME    = var.db_name
      DB_USER    = var.db_user
      DB_PASS    = var.db_password
      DB_PORT    = tostring(var.db_port)
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }
}

resource "aws_lambda_event_source_mapping" "process_order" {
  event_source_arn = var.queue_arn
  function_name    = aws_lambda_function.process_order.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.name_prefix}-api"
  description = "API REST hibrida FreshBox EP3"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "products"
}

resource "aws_api_gateway_resource" "product" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.products.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "cart" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "cart"
}

resource "aws_api_gateway_resource" "cart_item" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.cart.id
  path_part   = "{productId}"
}

resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "orders"
}

# --- Productos: API Gateway -> ALB -> EKS ---
resource "aws_api_gateway_method" "products_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "products_get" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.products_get.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "http://${local.alb_host}/api/products"
}

resource "aws_api_gateway_method" "products_post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "products_post" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.products_post.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "POST"
  uri                     = "http://${local.alb_host}/api/products"
}

resource "aws_api_gateway_method" "product_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.product.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "product_get" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.product.id
  http_method             = aws_api_gateway_method.product_get.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "http://${local.alb_host}/api/products/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

resource "aws_api_gateway_method" "product_put" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.product.id
  http_method   = "PUT"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "product_put" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.product.id
  http_method             = aws_api_gateway_method.product_put.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "PUT"
  uri                     = "http://${local.alb_host}/api/products/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

resource "aws_api_gateway_method" "product_delete" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.product.id
  http_method   = "DELETE"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "product_delete" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.product.id
  http_method             = aws_api_gateway_method.product_delete.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "DELETE"
  uri                     = "http://${local.alb_host}/api/products/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# --- Carrito: API Gateway -> Lambda Cart ---
resource "aws_api_gateway_method" "cart_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.cart.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cart_get" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.cart.id
  http_method             = aws_api_gateway_method.cart_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.cart.arn}/invocations"
}

resource "aws_api_gateway_method" "cart_post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.cart.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cart_post" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.cart.id
  http_method             = aws_api_gateway_method.cart_post.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.cart.arn}/invocations"
}

resource "aws_api_gateway_method" "cart_delete" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.cart_item.id
  http_method   = "DELETE"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.productId" = true
  }
}

resource "aws_api_gateway_integration" "cart_delete" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.cart_item.id
  http_method             = aws_api_gateway_method.cart_delete.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.cart.arn}/invocations"
}

# --- Ordenes: API Gateway -> Lambda Create-Order ---
resource "aws_api_gateway_method" "orders_post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "orders_post" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.orders_post.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.create_order.arn}/invocations"
}

# --- CORS para las 5 rutas base ---
locals {
  cors_resources = {
    products  = aws_api_gateway_resource.products.id
    product   = aws_api_gateway_resource.product.id
    cart      = aws_api_gateway_resource.cart.id
    cart_item = aws_api_gateway_resource.cart_item.id
    orders    = aws_api_gateway_resource.orders.id
  }
}

resource "aws_api_gateway_method" "cors" {
  for_each = local.cors_resources

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value
  http_method = aws_api_gateway_method.cors[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "cors" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value
  http_method = aws_api_gateway_method.cors[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "cors" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value
  http_method = aws_api_gateway_method.cors[each.key].http_method
  status_code = aws_api_gateway_method_response.cors[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  response_templates = {
    "application/json" = "{}"
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      var.alb_dns,
      aws_lambda_function.cart.arn,
      aws_lambda_function.create_order.arn,
      aws_api_gateway_resource.api.id,
      aws_api_gateway_resource.products.id,
      aws_api_gateway_resource.product.id,
      aws_api_gateway_resource.cart.id,
      aws_api_gateway_resource.cart_item.id,
      aws_api_gateway_resource.orders.id,
      aws_api_gateway_method.products_get.id,
      aws_api_gateway_method.products_post.id,
      aws_api_gateway_method.product_get.id,
      aws_api_gateway_method.product_put.id,
      aws_api_gateway_method.product_delete.id,
      aws_api_gateway_method.cart_get.id,
      aws_api_gateway_method.cart_post.id,
      aws_api_gateway_method.cart_delete.id,
      aws_api_gateway_method.orders_post.id,
      aws_api_gateway_integration.products_get.id,
      aws_api_gateway_integration.products_post.id,
      aws_api_gateway_integration.product_get.id,
      aws_api_gateway_integration.product_put.id,
      aws_api_gateway_integration.product_delete.id,
      aws_api_gateway_integration.cart_get.id,
      aws_api_gateway_integration.cart_post.id,
      aws_api_gateway_integration.cart_delete.id,
      aws_api_gateway_integration.orders_post.id,
      aws_api_gateway_integration_response.cors["products"].id,
      aws_api_gateway_integration_response.cors["product"].id,
      aws_api_gateway_integration_response.cors["cart"].id,
      aws_api_gateway_integration_response.cors["cart_item"].id,
      aws_api_gateway_integration_response.cors["orders"].id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "prod"
}

resource "aws_lambda_permission" "cart" {
  statement_id  = "AllowAPIGatewayCart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cart.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "create_order" {
  statement_id  = "AllowAPIGatewayCreateOrder"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
