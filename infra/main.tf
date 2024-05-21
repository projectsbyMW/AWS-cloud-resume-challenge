terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  profile = "prod"
  region = "us-east-1"
               }

resource "aws_s3_bucket" "resume_deploy" {
  bucket = "madheshwaranresumedeploy"
}

resource "aws_s3_bucket_cors_configuration" "resume_deploy" {
 bucket = aws_s3_bucket.resume_deploy.id
 cors_rule {
    allowed_headers = [ "*" ]
    allowed_methods = [ "GET","PUT","POST","DELETE","HEAD" ]
    allowed_origins = [ "*" ]
    expose_headers  = ["ETag","x-amz-meta-custom-header"]
    max_age_seconds = 0
  }
}

resource "aws_s3_bucket_ownership_controls" "resume_deploy" {
  bucket = aws_s3_bucket.resume_deploy.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "resume_deploy" {
  bucket = aws_s3_bucket.resume_deploy.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "resume_deploy" {
  depends_on = [
    aws_s3_bucket_ownership_controls.resume_deploy,
    aws_s3_bucket_public_access_block.resume_deploy,
  ]

  bucket = aws_s3_bucket.resume_deploy.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.resume_deploy.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["381492075565"]
    }

    actions = [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:PutObjectAcl"
              ]

    resources = [
      aws_s3_bucket.resume_deploy.arn,
      "${aws_s3_bucket.resume_deploy.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_website_configuration" "resume_deploy" {
  bucket = aws_s3_bucket.resume_deploy.id
  index_document {
    suffix = "index.html"
  }
}

output "s3_website_endpoint" {
  value = aws_s3_bucket_website_configuration.resume_deploy.website_endpoint
}

resource "aws_iam_role_policy" "Dynamo_policy" {
  name = "Dynamo_policy"
  role = aws_iam_role.DynamoDB_Access_For_Lambda.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:ListTables",
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem"
      ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role" "DynamoDB_Access_For_Lambda" {
  name               = "DynamoDB_Access_For_Lambda"

assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_lambda_function" "lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  function_name = "Lambda_for_DynamoDB"
  role          = aws_iam_role.DynamoDB_Access_For_Lambda.arn
  handler       = "lambdafunction.lambda_handler"
  s3_bucket = "madheshwaranresumedeploy"
  s3_key = "infra/bundle.zip"
  runtime = "python3.12"

  environment {
    variables = {
      foo = "bar"
    }
  }
}


# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "Website_Count"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "Website_Visitors_Count"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-east-1:381492075565:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}




resource "aws_api_gateway_method_response" "resume_deploy" {
  depends_on      = [aws_api_gateway_method.method]
  rest_api_id     = aws_api_gateway_rest_api.api.id
  resource_id     = aws_api_gateway_resource.resource.id
  http_method     = aws_api_gateway_method.method.http_method
  status_code     = 200
  response_models = { "application/json" = "Empty" }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true,
  }
}
resource "aws_api_gateway_integration_response" "integrationresponse" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.resume_deploy.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS,GET,PUT,PATCH,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
resource "aws_api_gateway_deployment" "resume_deploy" {
  depends_on  = [aws_api_gateway_integration_response.integrationresponse, aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev1"
}

resource "aws_dynamodb_table" "Website_Count" {
  name           = "Website_Count"
  billing_mode   = "PAY_PER_REQUEST"

  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}

resource "aws_dynamodb_table_item" "Website_Count" {
  table_name = aws_dynamodb_table.Website_Count.name
  hash_key   = aws_dynamodb_table.Website_Count.hash_key

  item = <<ITEM
{
  "Id": {"S": "Visitors_Count"},
  "Visitors": {"N": "0"}
}
ITEM
}
