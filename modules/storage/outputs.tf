output "serverless_bucket_arn" {
  description = "S3 Serverless Bucket ARN"
  value = aws_s3_bucket.serverless_s3_bucket.arn
}

output "serverless_bucket_domain_name" {
  description = "S3 Serverless Bucket Domian Name"
  value = aws_s3_bucket.serverless_s3_bucket.bucket_domain_name
}

output "serverless_bucket_id" {
  description = "S3 Serverless Bucket Id"
  value = aws_s3_bucket.serverless_s3_bucket.id
}