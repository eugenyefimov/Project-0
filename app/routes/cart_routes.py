from flask import Blueprint, render_template, request, redirect, url_for, session, jsonify, flash
from flask import current_app as app
import os
import uuid
from datetime import datetime

cart_bp = Blueprint('cart', __name__, url_prefix='/cart')

def get_cart_id():
    if 'cart_id' not in session:
        session['cart_id'] = str(uuid.uuid4())
    return session['cart_id']

@cart_bp.route('/')
def view_cart():
    cart_id = get_cart_id()
    carts_table = app.dynamo.tables[os.environ.get('CARTS_TABLE', 'carts')]
    
    cart = carts_table.get_item(Key={'id': cart_id}).get('Item')
    
    if not cart:
        cart = {
            'id': cart_id,
            'items': [],
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }
        carts_table.put_item(Item=cart)
    
    # Get product details for each item in cart
    cart_items = []
    total = 0
    
    products_table = app.dynamo.tables[os.environ.get('PRODUCTS_TABLE', 'products')]
    
    for item in cart.get('items', []):
        product = products_table.get_item(Key={'id': item['product_id']}).get('Item')
        if product:
            item_total = float(product['price']) * item['quantity']
            total += item_total
            cart_items.append({
                'product_id': item['product_id'],
                'quantity': item['quantity'],
                'product': product
            })
    
    return render_template('cart/view.html', cart_items=cart_items, total=total)

@cart_bp.route('/add', methods=['POST'])
def add_to_cart():
    product_id = request.form.get('product_id')
    quantity = int(request.form.get('quantity', 1))
    
    if not product_id:
        flash('Product ID is required', 'error')
        return redirect(url_for('product.list_products'))
    
    # Get cart
    cart_id = get_cart_id()
    carts_table = app.dynamo.tables[os.environ.get('CARTS_TABLE', 'carts')]
    
    cart = carts_table.get_item(Key={'id': cart_id}).get('Item')
    
    if not cart:
        cart = {
            'id': cart_id,
            'items': [],
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }
    
    # Check if product already in cart
    found = False
    for item in cart.get('items', []):
        if item['product_id'] == product_id:
            item['quantity'] += quantity
            found = True
            break
    
    if not found:
        cart.setdefault('items', []).append({
            'product_id': product_id,
            'quantity': quantity
        })
    
    cart['updated_at'] = datetime.now().isoformat()
    
    # Update cart in DynamoDB
    carts_table.put_item(Item=cart)
    
    flash('Product added to cart', 'success')
    return redirect(url_for('cart.view_cart'))

@cart_bp.route('/remove', methods=['POST'])
def remove_from_cart():
    product_id = request.form.get('product_id')
    
    if not product_id:
        flash('Product ID is required', 'error')
        return redirect(url_for('cart.view_cart'))
    
    # Get cart
    cart_id = get_cart_id()
    carts_table = app.dynamo.tables[os.environ.get('CARTS_TABLE', 'carts')]
    
    cart = carts_table.get_item(Key={'id': cart_id}).get('Item')
    
    if not cart:
        flash('Your cart is empty', 'error')
        return redirect(url_for('cart.view_cart'))
    
    # Remove item from cart
    cart['items'] = [item for item in cart.get('items', []) if item['product_id'] != product_id]
    cart['updated_at'] = datetime.now().isoformat()
    
    # Update cart in DynamoDB
    carts_table.put_item(Item=cart)
    
    flash('Product removed from cart', 'success')
    return redirect(url_for('cart.view_cart'))

@cart_bp.route('/remove-item', methods=['POST'])
def remove_item():
    # This is an alias for remove_from_cart to match the template
    return remove_from_cart()