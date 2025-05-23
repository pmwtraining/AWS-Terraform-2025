# Create API Gateway with Rest API type
resource "aws_api_gateway_rest_api" "example" {
  name        = "Serverless"
  description = "Serverless Application using Terraform"
}

# Defines a resource in the API Gateway that will capture any request path. The path_part = "{proxy+}" allows API Gateway to match all requests that have any path pattern, enabling dynamic routing.
resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.example.id
   parent_id   = aws_api_gateway_rest_api.example.root_resource_id
   path_part   = "{proxy+}"     # with proxy, this resource will match any request path
}

# Configures to allow any HTTP method (GET, POST, DELETE, etc.) and does not require any specific authorization. It's set for the previously defined proxy resource.
resource "aws_api_gateway_method" "proxy" {
   rest_api_id   = aws_api_gateway_rest_api.example.id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "ANY"       # with ANY, it allows any request method to be used, all incoming requests will match this resource
   authorization = "NONE"
}

# API Gateway - Lambda Connection
# The AWS_PROXY type means API Gateway will directly pass the request details (method, headers, body, path parameters, etc.) to the Lambda function
resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.example.id
   resource_id = aws_api_gateway_method.proxy.resource_id
   http_method = aws_api_gateway_method.proxy.http_method
   integration_http_method = "POST"
   type                    = "AWS_PROXY"  # With AWS_PROXY, it causes API gateway to call into the API of another AWS service
   uri                     = aws_lambda_function.lambda_function.invoke_arn
}

# The proxy resource cannot match an empty path at the root of the API. API GW doesn't route requests to the root (/) path using the proxy, so a separate method and integration for the root resource are required.
# To handle that, a similar configuration must be applied to the root resource that is built in to the REST API object.
# This ensures that requests to the root (e.g., https://api.example.com/) are also forwarded to the Lambda function.
resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.example.id
   resource_id   = aws_api_gateway_rest_api.example.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.example.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method
   integration_http_method = "POST"
   type                    = "AWS_PROXY"  # With AWS_PROXY, it causes API gateway to call into the API of another AWS service
   uri                     = aws_lambda_function.lambda_function.invoke_arn
}

# Deploy API Gateway
# Deploys the API to the specified stage (test stage). The depends_on ensures that the API is not deployed until both the Lambda integrations (for proxy and root) are complete.
resource "aws_api_gateway_deployment" "example" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]
   rest_api_id = aws_api_gateway_rest_api.example.id
   stage_name  = "test"
}

# Output to the URL 
output "base_url" {
  value = aws_api_gateway_deployment.example.invoke_url
}
