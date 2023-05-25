# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.0"
#     }
#   }
# }
# provider "aws" {
#   region  = "us-east-1"
#   profile = "vscode"
# }

# API Gateway #=================================================================
resource "aws_api_gateway_rest_api" "serverless_deploy_api" {
  name = "${var.serverless_deploy_api_name}"
  description = "Serverless deployment REST API"

    endpoint_configuration {
    types = ["EDGE"]
  }

  tags = {
    Name = "${var.serverless_deploy_api_name}"
    Environment = "${var.environment}"
    project = "${var.project}"
  }
}

resource "aws_api_gateway_resource" "serverless_deploy_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.serverless_deploy_api.id
  parent_id = aws_api_gateway_rest_api.serverless_deploy_api.root_resource_id
  path_part = "serverless-deployment"
}

resource "aws_api_gateway_method" "serverless_deploy_api_get_method" {
  rest_api_id = aws_api_gateway_rest_api.serverless_deploy_api.id
  resource_id = aws_api_gateway_resource.serverless_deploy_api_resource.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "serverless_deploy_integration" {
  rest_api_id          = aws_api_gateway_rest_api.serverless_deploy_api.id
  resource_id          = aws_api_gateway_resource.serverless_deploy_api_resource.id
  http_method          = aws_api_gateway_method.serverless_deploy_api_get_method.http_method
  integration_http_method = "GET"
  type = "AWS_PROXY"
  uri = "${aws_lambda_function.lambda_get_function.invoke_arn}"
}

resource "aws_api_gateway_method_response" "serverless_deploy_get_response_200" {
  rest_api_id = aws_api_gateway_rest_api.serverless_deploy_api.id
  resource_id = aws_api_gateway_resource.serverless_deploy_api_resource.id
  http_method = aws_api_gateway_method.serverless_deploy_api_get_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "serverless_deploy_get_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.serverless_deploy_api.id
  resource_id = aws_api_gateway_resource.serverless_deploy_api_resource.id
  http_method = aws_api_gateway_method.serverless_deploy_api_get_method.http_method
  status_code = aws_api_gateway_method_response.serverless_deploy_get_response_200.status_code
}


resource "aws_api_gateway_deployment" "serverless_deploy" {
  rest_api_id = aws_api_gateway_rest_api.serverless_deploy_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.serverless_deploy_api_resource.id,
      aws_api_gateway_method.serverless_deploy_api_get_method.id,
      aws_api_gateway_integration.serverless_deploy_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "serverless_deploy_stage" {
  deployment_id = aws_api_gateway_deployment.serverless_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.serverless_deploy_api.id
  stage_name    = "${var.serverless_deploy_api_stage}"
}

resource "aws_api_gateway_base_path_mapping" "api_mapping" {
  api_id      = aws_api_gateway_rest_api.serverless_deploy_api.id
  stage_name  = aws_api_gateway_stage.serverless_deploy_stage.stage_name
  domain_name = "${var.serverless_deploy_domain_name}"
}

# Lambda #=================================================================
resource "aws_iam_role" "serverless_deploy_dynamo_db_crud_role" {
  name     = "serverless_deploy_dynamo_db_crud_role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

data "aws_iam_policy_document" "dynamo_db_crud" {
  statement {
    sid = "1"
    
    effect = "Allow"

    actions = [
                "dynamodb:GetItem",
                "dynamodb:DeleteItem",
                "dynamodb:PutItem",
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:UpdateItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:BatchGetItem",
                "dynamodb:DescribeTable",
                "dynamodb:ConditionCheckItem"
    ]

    resources = [
      "${var.aws_dynamo_db_arn}",
    ]
  }
}

resource "aws_iam_policy" "serverless_deploy_dynamo_db_crud_policy" {
  name   = "serverless_deploy_dynamo_db_crud"
  policy = data.aws_iam_policy_document.dynamo_db_crud.json
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role = aws_iam_role.serverless_deploy_dynamo_db_crud_role.name
  policy_arn = aws_iam_policy.serverless_deploy_dynamo_db_crud_policy.arn
}

data "archive_file" "lambda_payload" {
  type        = "zip"
  source_dir  = "${path.module}/handler"
  output_path = "${path.module}/lambda_function_payload.zip"
}


resource "aws_lambda_function" "lambda_get_function" {
  filename      = "${path.module}/lambda_function_payload.zip"
  function_name = "serverless_lambda_get_function"
  role          = aws_iam_role.serverless_deploy_dynamo_db_crud_role.arn
  handler       = "site_visitors.lambda_handler"

  source_code_hash = data.archive_file.lambda_payload.output_base64sha256

  runtime = "python3.9"

}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_get_function.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.serverless_deploy_api.execution_arn}/*/${aws_api_gateway_method.serverless_deploy_api_get_method.http_method}${aws_api_gateway_resource.serverless_deploy_api_resource.path}"
}