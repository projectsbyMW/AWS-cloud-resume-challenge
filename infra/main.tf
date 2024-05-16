terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region  = "us-east-1"
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
    expose_headers  = ["ETag"]
    max_age_seconds = 0
  }

}

resource "aws_s3_bucket_website_configuration" "resume_deploy" {
  bucket = aws_s3_bucket.resume_deploy.id
  index_document {
    suffix = "index.html"
  }
}

output "s3_website_endpoint" {
  value = aws_s3_bucket.resume_deploy.website_endpoint
}