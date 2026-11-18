output "api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "api_invoke_url" {
  value = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${data.aws_region.current.region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}

output "cart_lambda_name" {
  value = aws_lambda_function.cart.function_name
}

output "create_order_lambda_name" {
  value = aws_lambda_function.create_order.function_name
}

output "process_order_lambda_name" {
  value = aws_lambda_function.process_order.function_name
}

output "process_order_event_source_mapping" {
  value = aws_lambda_event_source_mapping.process_order.id
}
