# API Gateway resource
resource "aws_apigatewayv2_api" "apigw" {
  name          = "example-http-api"
  protocol_type = "HTTP"

  tags = {
    Name        = "API Gateway"
    Environment = "Production"
  }
}

# API Gateway Integration
resource "aws_apigatewayv2_integration" "apigw" {
  api_id           = aws_apigatewayv2_api.apigw.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description        = "Lambda example"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.lambda_1.invoke_arn
}

# API Gateway Routes
resource "aws_apigatewayv2_route" "apigwroute1" {
  api_id    = aws_apigatewayv2_api.apigw.id
  route_key = "POST /scan"

  target = "integrations/${aws_apigatewayv2_integration.apigw.id}"
}
resource "aws_apigatewayv2_route" "apigwroute2" {
  api_id    = aws_apigatewayv2_api.apigw.id
  route_key = "GET /scan/{scan_id}"

  target = "integrations/${aws_apigatewayv2_integration.apigw.id}"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "apigw" {
  api_id      = aws_apigatewayv2_api.apigw.id
  name        = "$default"
  auto_deploy = true
}

