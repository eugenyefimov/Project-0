from flask import Flask, render_template, request, redirect, url_for, session, jsonify
from flask_dynamo import Dynamo
import boto3
import os
import uuid
from datetime import datetime
import json
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key')

# Configure DynamoDB
app.config['DYNAMO_ENABLE_LOCAL'] = False
app.config['DYNAMO_TABLES'] = [
    {
        'TableName': os.environ.get('PRODUCTS_TABLE', 'products'),
        'KeySchema': [dict(AttributeName='id', KeyType='HASH')],
        'AttributeDefinitions': [dict(AttributeName='id', AttributeType='S')],
        'ProvisionedThroughput': dict(ReadCapacityUnits=5, WriteCapacityUnits=5)
    },
    {
        'TableName': os.environ.get('CARTS_TABLE', 'carts'),
        'KeySchema': [dict(AttributeName='id', KeyType='HASH')],
        'AttributeDefinitions': [dict(AttributeName='id', AttributeType='S')],
        'ProvisionedThroughput': dict(ReadCapacityUnits=5, WriteCapacityUnits=5)
    },
    {
        'TableName': os.environ.get('ORDERS_TABLE', 'orders'),
        'KeySchema': [dict(AttributeName='id', KeyType='HASH')],
        'AttributeDefinitions': [dict(AttributeName='id', AttributeType='S')],
        'ProvisionedThroughput': dict(ReadCapacityUnits=5, WriteCapacityUnits=5)
    }
]

# Initialize DynamoDB
dynamo = Dynamo(app)

# Configure S3
s3 = boto3.client('s3',
    region_name=os.environ.get('AWS_REGION', 'us-east-1')
)
BUCKET_NAME = os.environ.get('S3_BUCKET', 'project0-static-assets')

# Fix for running behind a proxy
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_port=1)

# Import blueprints
from app.routes.product_routes import product_bp
from app.routes.cart_routes import cart_bp
from app.routes.order_routes import order_bp
from app.routes.user_routes import user_bp

# Register blueprints
app.register_blueprint(product_bp, url_prefix='/products')
app.register_blueprint(cart_bp, url_prefix='/cart')
app.register_blueprint(order_bp, url_prefix='/orders')
app.register_blueprint(user_bp, url_prefix='/user')

@app.route('/')
def index():
    # Get products from DynamoDB (mock data for now)
    products = [
        {
            'id': '1',
            'name': 'Product 1',
            'description': 'This is product 1',
            'price': '19.99',
            'stock': 10
        },
        {
            'id': '2',
            'name': 'Product 2',
            'description': 'This is product 2',
            'price': '29.99',
            'stock': 5
        }
    ]
    
    return render_template('index.html', products=products)

@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

@app.errorhandler(500)
def server_error(e):
    return render_template('500.html'), 500

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)