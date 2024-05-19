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
