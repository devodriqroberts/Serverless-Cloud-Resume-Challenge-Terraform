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

# Dynamo DB #=================================================================
resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "${var.dynamo_db_table_name}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ID"

  attribute {
    name = "ID"
    type = "S"
  }

  tags = {
    Name = "${var.dynamo_db_table_name}"
    Environment = "${var.environment}"
    project = "${var.project}"
  }
}

# resource "aws_dynamodb_table_item" "visitor_count_item" {
#   table_name = aws_dynamodb_table.dynamodb_table.name
#   hash_key   = aws_dynamodb_table.dynamodb_table.hash_key

#   item = <<ITEM
#   {
#     "ID": {"S": "VisitorCount"},
#     "VisitorCount": {"N": "0"}
#   }
#   ITEM
# }