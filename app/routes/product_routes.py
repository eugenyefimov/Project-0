from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from flask import current_app as app
import boto3
import os
import uuid
from datetime import datetime

product_bp = Blueprint('product', __name__, url_prefix='/products')

@product_bp.route('/')
def list_products():
    products_table = app.dynamo.tables[os.environ.get('PRODUCTS_TABLE', 'products')]
    products = list(products_table.scan()['Items'])
    return render_template('products/list.html', products=products)

@product_bp.route('/<product_id>')
def view_product(product_id):
    products_table = app.dynamo.tables[os.environ.get('PRODUCTS_TABLE', 'products')]
    product = products_table.get_item(Key={'id': product_id}).get('Item')
    
    if not product:
        flash('Product not found', 'error')
        return redirect(url_for('product.list_products'))
    
    return render_template('products/detail.html', product=product)

@product_bp.route('/api/products')
def api_list_products():
    products_table = app.dynamo.tables[os.environ.get('PRODUCTS_TABLE', 'products')]
    products = list(products_table.scan()['Items'])
    return jsonify(products)

@product_bp.route('/api/products/<product_id>')
def api_get_product(product_id):
    products_table = app.dynamo.tables[os.environ.get('PRODUCTS_TABLE', 'products')]
    product = products_table.get_item(Key={'id': product_id}).get('Item')
    
    if not product:
        return jsonify({'error': 'Product not found'}), 404
    
    return jsonify(product)