terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "vscode"
}


# # S3 Storage #====================================
module "storage" {
  source                 = "./modules/storage"
  serverless_bucket_name = var.serverless_bucket_name
  environment            = var.environment
  project                = var.project
}

# Network #====================================
module "networking" {
  source                   = "./modules/networking"
  domain_name              = var.domain_name
  s3_bucket_domain_name    = module.storage.serverless_bucket_domain_name
  hostedzone_id            = var.hostedzone_id
  cloudfront_hostedzone_id = var.cloudfront_hostedzone_id
  serverless_bucket_id     = module.storage.serverless_bucket_id
  environment              = var.environment
  project                  = var.project
}

# Database #====================================
module "database" {
  source               = "./modules/database"
  dynamo_db_table_name = var.dynamo_db_table_name
  environment          = var.environment
  project              = var.project
}

# Application #====================================
module "application" {
  source                        = "./modules/application"
  serverless_deploy_api_name    = var.serverless_deploy_api_name
  serverless_deploy_api_stage   = var.serverless_deploy_api_stage
  serverless_deploy_domain_name = module.networking.serverless_deploy_domain_name
  aws_dynamo_db_arn             = module.database.aws_dynamo_db_arn
  environment                   = var.environment
  project                       = var.project
}