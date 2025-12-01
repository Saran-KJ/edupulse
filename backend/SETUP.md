# Backend Setup Guide

## Prerequisites

- Python 3.9 or higher
- PostgreSQL 12 or higher
- pip (Python package manager)

## Installation Steps

### 1. Install PostgreSQL

Download and install PostgreSQL from https://www.postgresql.org/download/

### 2. Create Database

```sql
-- Open PostgreSQL command line or pgAdmin
CREATE DATABASE edupulse;
CREATE USER edupulse_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE edupulse TO edupulse_user;
```

### 3. Set Up Python Environment

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 4. Configure Environment Variables

Create a `.env` file in the backend directory:

```env
DATABASE_URL=postgresql://edupulse_user:your_password@localhost:5432/edupulse
SECRET_KEY=your-super-secret-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

**Important**: Change the SECRET_KEY to a random string in production!

### 5. Initialize Database with Sample Data

```bash
python init_db.py
```

This will create all tables and add sample data including:
- Admin user: admin@edupulse.com / admin123
- Staff user: staff@edupulse.com / staff123
- 3 sample students with marks and attendance

### 6. Run the Server

```bash
python main.py
```

The API will be available at:
- API: http://localhost:8000
- Interactive Docs: http://localhost:8000/docs
- Alternative Docs: http://localhost:8000/redoc

## Testing the API

### Using Swagger UI

1. Open http://localhost:8000/docs
2. Click on "Authorize" button
3. Login using POST /api/auth/login with:
   - username: admin@edupulse.com
   - password: admin123
4. Copy the access_token from response
5. Paste in the authorization dialog (format: Bearer <token>)
6. Now you can test all endpoints

### Using curl

```bash
# Login
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@edupulse.com&password=admin123"

# Get students (use token from login response)
curl -X GET "http://localhost:8000/api/students" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Common Issues

### Issue: Database connection error

**Solution**: Check your DATABASE_URL in .env file and ensure PostgreSQL is running

### Issue: Module not found

**Solution**: Make sure virtual environment is activated and dependencies are installed

### Issue: Port 8000 already in use

**Solution**: Change port in main.py or kill the process using port 8000

## Production Deployment

For production deployment:

1. Use a strong SECRET_KEY
2. Set up proper PostgreSQL user with limited permissions
3. Use environment variables for sensitive data
4. Enable HTTPS
5. Set up proper CORS origins (not *)
6. Use a production WSGI server like gunicorn:

```bash
pip install gunicorn
gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```
