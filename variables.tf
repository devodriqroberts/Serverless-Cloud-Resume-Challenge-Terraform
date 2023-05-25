variable "region" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "dynamo_db_table_name" {
  type = string
}

variable "hostedzone_id" {
  type = string
}

variable "cloudfront_hostedzone_id" {
  type = string
}
variable "environment" {
  type = string
}

variable "serverless_bucket_name" {
  type = string
}

variable "project" {
  type = string
}

variable "serverless_deploy_api_name" {
  type = string
}

variable "serverless_deploy_api_stage" {
  type = string
}