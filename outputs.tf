# API Gateway Output
output "aws_apigateway_api" {
  description = "The API."
  value       = aws_apigatewayv2_api.apigw.api_endpoint
}

# API Gateway Stage
output "stage_arn" {
  value = aws_apigatewayv2_stage.apigw.arn
}