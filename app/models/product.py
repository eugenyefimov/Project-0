import boto3
import os
from datetime import datetime
import uuid

class Product:
    def __init__(self, dynamodb=None):
        self.table_name = os.environ.get('PRODUCTS_TABLE', 'products')
        if not dynamodb:
            self.dynamodb = boto3.resource('dynamodb')
        else:
            self.dynamodb = dynamodb
        self.table = self.dynamodb.Table(self.table_name)
    
    def get_all(self):
        response = self.table.scan()
        return response.get('Items', [])
    
    def get_by_id(self, product_id):
        response = self.table.get_item(
            Key={'id': product_id}
        )
        return response.get('Item')
    
    def create(self, name, description, price, image_url):
        timestamp = datetime.utcnow().isoformat()
        item = {
            'id': str(uuid.uuid4()),
            'name': name,
            'description': description,
            'price': price,
            'image_url': image_url,
            'created_at': timestamp,
            'updated_at': timestamp
        }
        self.table.put_item(Item=item)
        return item