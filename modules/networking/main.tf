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

# ACM Certificate #=================================================================
resource "aws_acm_certificate" "cert" {
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"
  subject_alternative_names = ["${var.domain_name}", "*.${var.domain_name}"]
  tags = {
    Name = "Serverless Cloud Resume Challenge ACM Certificate"
    Environment = "${var.environment}"
    project = "${var.project}"
  }
}

# Route 53 Records #=================================================================
resource "aws_route53_record" "www" {
  zone_id = "${var.hostedzone_id}"
  name    = "${var.domain_name}"
  type    = "A"
  alias {
    name = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id = "${var.cloudfront_hostedzone_id}"
    evaluate_target_health = false
  }
}

resource "aws_api_gateway_domain_name" "serverless_deploy_domain_name" {
  certificate_arn = aws_acm_certificate.cert.arn
  domain_name     = "api.${var.domain_name}"
}

resource "aws_route53_record" "api" {
  zone_id = "${var.hostedzone_id}"
  name    = aws_api_gateway_domain_name.serverless_deploy_domain_name.domain_name
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.serverless_deploy_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.serverless_deploy_domain_name.cloudfront_zone_id
  }
}


# Cloudfront Distribution #=================================================================
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = "${var.s3_bucket_domain_name}"
    origin_id                = "${var.serverless_bucket_id}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
      http_port = 80
      https_port = 443
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloud Resume Challenge Serverless Distribution"
  default_root_object = "index.html"

  aliases = ["${var.domain_name}"]
  http_version = "http2and3"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.serverless_bucket_id}"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "${var.environment}"
    project = "${var.project}"
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}