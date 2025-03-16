import os
from dotenv import load_dotenv
from app.app import app

# Load environment variables from .env file
load_dotenv()

if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=int(os.environ.get('PORT', 5000)),
        debug=os.environ.get('FLASK_ENV', 'production') == 'development'
    )