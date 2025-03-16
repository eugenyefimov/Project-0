from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from flask import current_app as app
import os
import uuid
from datetime import datetime

user_bp = Blueprint('user', __name__, url_prefix='/user')

@user_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
        return render_template('user/login.html')
    
    # Simple login for demo purposes
    email = request.form.get('email')
    password = request.form.get('password')
    
    if email == 'demo@example.com' and password == 'password':
        session['user_id'] = 'demo-user'
        session['user_email'] = email
        flash('Logged in successfully', 'success')
        return redirect(url_for('index'))
    
    flash('Invalid credentials', 'error')
    return redirect(url_for('user.login'))

@user_bp.route('/logout')
def logout():
    session.pop('user_id', None)
    session.pop('user_email', None)
    flash('Logged out successfully', 'success')
    return redirect(url_for('index'))

@user_bp.route('/profile')
def profile():
    if 'user_id' not in session:
        flash('Please login to view your profile', 'error')
        return redirect(url_for('user.login'))
    
    return render_template('user/profile.html')