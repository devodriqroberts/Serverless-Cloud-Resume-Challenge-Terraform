output "acm_certificate_arn" {
    description = "ACM Certificate ARN"
  value = aws_acm_certificate.cert.arn
}

output "serverless_deploy_domain_name" {
  value = aws_api_gateway_domain_name.serverless_deploy_domain_name.domain_name
}