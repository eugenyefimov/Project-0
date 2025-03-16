from flask import Blueprint, render_template, request, redirect, url_for, session, jsonify, flash
from flask import current_app as app
import os
import uuid
from datetime import datetime

order_bp = Blueprint('order', __name__, url_prefix='/orders')

@order_bp.route('/')
def list_orders():
    # Check if user is logged in
    if 'user_id' not in session:
        flash('Please log in to view your orders', 'warning')
        return redirect(url_for('user.login'))
    
    user_id = session['user_id']
    orders_table = app.dynamo.tables[os.environ.get('ORDERS_TABLE', 'orders')]
    
    # Get orders for the user
    # In a real app, you'd use a GSI to query by user_id
    # For simplicity, we'll scan and filter
    response = orders_table.scan()
    orders = [order for order in response.get('Items', []) if order.get('user_id') == user_id]
    
    return render_template('orders/list.html', orders=orders)

@order_bp.route('/checkout', methods=['GET', 'POST'])
def checkout():
    # Get cart
    cart_id = session.get('cart_id')
    if not cart_id:
        flash('Your cart is empty', 'warning')
        return redirect(url_for('product.list_products'))
    
    carts_table = app.dynamo.tables[os.environ.get('CARTS_TABLE', 'carts')]
    cart = carts_table.get_item(Key={'id': cart_id}).get('Item')
    
    if not cart or not cart.get('items'):
        flash('Your cart is empty', 'warning')
        return redirect(url_for('product.list_products'))
    
    # Get product details for each item in cart
    cart_items = []
    total_amount = 0
    
    products_table = app.dynamo.tables[os.environ.get('PRODUCTS_TABLE', 'products')]
    
    for item in cart.get('items', []):
        product = products_table.get_item(Key={'id': item['product_id']}).get('Item')
        if product:
            item_total = float(product['price']) * item['quantity']
            total_amount += item_total
            cart_items.append({
                'product_id': item['product_id'],
                'quantity': item['quantity'],
                'product': product
            })
    
    if request.method == 'GET':
        return render_template('orders/checkout.html', cart_items=cart_items, total_amount=total_amount)
    
    # Process checkout form
    name = request.form.get('name')
    email = request.form.get('email')
    address = request.form.get('address')
    
    if not all([name, email, address]):
        flash('Please fill in all required fields', 'error')
        return redirect(url_for('order.checkout'))
    
    # Create order
    order_id = str(uuid.uuid4())
    order = {
        'id': order_id,
        'user_id': session.get('user_id', 'guest'),
        'status': 'pending',
        'total_amount': total_amount,
        'items': [],
        'customer': {
            'name': name,
            'email': email,
            'address': address
        },
        'created_at': datetime.now().isoformat(),
        'updated_at': datetime.now().isoformat()
    }
    
    # Add items to order
    for item in cart_items:
        order['items'].append({
            'product_id': item['product_id'],
            'product_name': item['product']['name'],
            'price': item['product']['price'],
            'quantity': item['quantity'],
            'item_total': float(item['product']['price']) * item['quantity']
        })
    
    # Save order to DynamoDB
    orders_table = app.dynamo.tables[os.environ.get('ORDERS_TABLE', 'orders')]
    orders_table.put_item(Item=order)
    
    # Clear cart
    carts_table.delete_item(Key={'id': cart_id})
    session.pop('cart_id', None)
    
    # Redirect to order confirmation
    return redirect(url_for('order.confirmation', order_id=order_id))

@order_bp.route('/<order_id>')
def confirmation(order_id):
    # Check if user is logged in
    if 'user_id' not in session:
        flash('Please log in to view your orders', 'warning')
        return redirect(url_for('user.login'))
    
    orders_table = app.dynamo.tables[os.environ.get('ORDERS_TABLE', 'orders')]
    
    # Get order details
    order = orders_table.get_item(Key={'id': order_id}).get('Item')
    
    if not order:
        flash('Order not found', 'error')
        return redirect(url_for('order.list_orders'))
    
    # Check if the order belongs to the user
    if order.get('user_id') != session['user_id']:
        flash('You do not have permission to view this order', 'error')
        return redirect(url_for('order.list_orders'))
    
    return render_template('orders/confirmation.html', order=order)