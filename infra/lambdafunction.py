import json
import boto3
from boto3.dynamodb.conditions import Key #used to access DynamoDB table

TABLE_NAME = "Website_visit_count" 

# Creating the DynamoDB Client
dynamodb_client = boto3.client('dynamodb', region_name="us-east-1")

# Creating the DynamoDB Table Resource
dynamodb = boto3.resource('dynamodb', region_name="us-east-1")
table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    
    response = table.get_item(
    Key={
        "id":'Visitor_Count'
        }
                             )
    item=response['Item']
    
    table.update_item(
    Key={
        "id" : 'Visitor_Count',
        },
    UpdateExpression="SET Visitors = :val1",
    ExpressionAttributeValues={
               ':val1': item['Visitors'] + 1
                              }
                     )
    
    return{
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
                   },
        "body": json.dumps({"Total_Visitors": str(item['Visitors'] + 1)})
          }