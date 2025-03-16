from flask import Blueprint, render_template, request, redirect, url_for, session, jsonify, flash
from flask import current_app as app
import os
import uuid
from datetime import datetime

order_bp = Blueprint('order', __name__, url_prefix='/orders')

@order_bp.route('/')
def list_orders():
    # Simple implementation - in a real app, you'd check user authentication
    return render_template('orders/list.html', orders=[])

@order_bp.route('/checkout', methods=['GET', 'POST'])
def checkout():
    if request.method == 'GET':
        return render_template('orders/checkout.html')
    
    # Process checkout form
    name = request.form.get('name')
    email = request.form.get('email')
    address = request.form.get('address')
    
    if not all([name, email, address]):
        flash('Please fill in all required fields', 'error')
        return redirect(url_for('order.checkout'))
    
    # Get cart
    cart_id = session.get('cart_id')
    if not cart_id:
        flash('Your cart is empty', 'error')
        return redirect(url_for('product.list_products'))
    
    carts_table = app.dynamo.tables[os.environ.get('CARTS_TABLE', 'carts')]
    cart = carts_table.get_item(Key={'id': cart_id}).get('Item')
    
    if not cart or not cart.get('items'):
        flash('Your cart is empty', 'error')
        return redirect(url_for('product.list_products'))
    
    # Create order
    order_id = str(uuid.uuid4())
    orders_table = app.dynamo.tables[os.environ.get('ORDERS_TABLE', 'orders')]
    
    # Get product details for each item in cart
    products_table = app.dynamo.tables[os.environ.get('PRODUCTS_TABLE', 'products')]
    order_items = []
    total_amount = 0
    
    for item in cart.get('items', []):
        product = products_table.get_item(Key={'id': item['product_id']}).get('Item')
        if product:
            price = float(product.get('price', 0))
            quantity = item.get('quantity', 1)
            item_total = price * quantity
            total_amount += item_total
            
            order_items.append({
                'product_id': item['product_id'],
                'product_name': product.get('name', 'Unknown'),
                'price': price,
                'quantity': quantity,
                'item_total': item_total
            })
    
    order = {
        'id': order_id,
        'customer': {
            'name': name,
            'email': email,
            'address': address
        },
        'items': order_items,
        'total_amount': total_amount,
        'status': 'pending',
        'created_at': datetime.now().isoformat()
    }
    
    # Save order to DynamoDB
    orders_table.put_item(Item=order)
    
    # Clear cart
    carts_table.delete_item(Key={'id': cart_id})
    session.pop('cart_id', None)
    
    flash('Order placed successfully', 'success')
    return redirect(url_for('order.confirmation', order_id=order_id))

@order_bp.route('/confirmation/<order_id>')
def confirmation(order_id):
    orders_table = app.dynamo.tables[os.environ.get('ORDERS_TABLE', 'orders')]
    order = orders_table.get_item(Key={'id': order_id}).get('Item')
    
    if not order:
        flash('Order not found', 'error')
        return redirect(url_for('product.list_products'))
    
    return render_template('orders/confirmation.html', order=order)