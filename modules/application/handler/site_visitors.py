import json
import boto3

DDB_TABLE_NAME = "cloud_resume_challenge_serverless"
DDB_CLIENT = boto3.client('dynamodb', region_name="us-east-1")
DDB_TABLE = boto3.resource('dynamodb', region_name="us-east-1")
TABLE = DDB_TABLE.Table(DDB_TABLE_NAME)

def lambda_handler(event, context):
  # try:
  res = TABLE.get_item(
    Key = {
      "ID" : "VisitorCount"
    }
  )
  visitor_count = res["Item"]['VisitorCount']
  new_visitor_count = visitor_count + 1

  TABLE.update_item(
    Key={
      "ID" : "VisitorCount"
    },
    UpdateExpression="SET VisitorCount = :val1",
    ExpressionAttributeValues={
      ":val1" : new_visitor_count
    }
  )
  # except:
  #   TABLE.put_item(
  #     Key = {
  #       "ID" : {"S": "VisitorCount"},
  #       "VisitorCount": {"N": 1}
  #     }
  #   )

  #   new_visitor_count = 1
  
  return {
    "statusCode": 200,
    "headers": {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "*",
      "Access-Control-Allow-Headers": "*"
    },
    "body": json.dumps({
      "visitors": str(new_visitor_count)
    }),
  }
