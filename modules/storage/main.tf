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

# Create Bucket #=================================================================
resource "aws_s3_bucket" "serverless_s3_bucket" {
  bucket = "${var.serverless_bucket_name}"

  tags = {
    Name = "${var.serverless_bucket_name}"
    Environment = "${var.environment}"
    Project = "${var.project}"
  }
}

# Website Hosting #=================================================================
resource "aws_s3_bucket_website_configuration" "serverless_s3_bucket_web_config" {
  bucket = aws_s3_bucket.serverless_s3_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# Allow Public Access #=================================================================
resource "aws_s3_bucket_policy" "serverless_s3_bucket_allow_public_access" {
  bucket = aws_s3_bucket.serverless_s3_bucket.id
  policy = data.aws_iam_policy_document.allow_public_access.json
}

# Remove Public Block #=================================================================
resource "aws_s3_bucket_public_access_block" "serverless_s3_bucket_remove_block" {
  bucket = aws_s3_bucket.serverless_s3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


# IAM Access Policy #=================================================================
data "aws_iam_policy_document" "allow_public_access" {
  statement {
    sid = "serverless_s3_bucket_allow_public_access"
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.serverless_s3_bucket.arn}/*"
    ]
  }
}