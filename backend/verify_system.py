import requests
import sys
import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Add current directory to path to import models/config
sys.path.append(os.getcwd())
from config import get_settings

def verify_database():
    print("\n--- Verifying Database ---")
    settings = get_settings()
    engine = create_engine(settings.database_url)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    
    try:
        # Check new tables exist and have data
        tables = ['students_cse', 'students_eee', 'students_bio', 'students_civil', 'students_aids']
        for table in tables:
            try:
                result = db.execute(text(f"SELECT count(*) FROM {table}"))
                count = result.scalar()
                print(f"✓ Table '{table}' exists. Row count: {count}")
            except Exception as e:
                print(f"✗ Table '{table}' check failed: {e}")
                
        # Check departments
        result = db.execute(text("SELECT count(*) FROM departments"))
        print(f"✓ Table 'departments' row count: {result.scalar()}")
        
    except Exception as e:
        print(f"✗ Database connection failed: {e}")
    finally:
        db.close()

def verify_api():
    print("\n--- Verifying Backend API ---")
    base_url = "http://127.0.0.1:8000"
    
    # Login to get token (using Admin)
    try:
        login_data = {"username": "admin65@gmail.com", "password": "1234678@"}
        response = requests.post(f"{base_url}/api/auth/login", data=login_data)
        if response.status_code != 200:
            print(f"✗ Login failed: {response.status_code} {response.text}")
            return
        
        token = response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print("✓ Login successful (Admin)")
        
        # 1. Get Students (CSE)
        print("\nTesting GET /api/students?dept=CSE")
        resp = requests.get(f"{base_url}/api/students?dept=CSE", headers=headers)
        if resp.status_code == 200:
            data = resp.json()
            print(f"✓ Success. Retrieved {len(data)} CSE students.")
            if len(data) > 0:
                print(f"  Sample: {data[0]['name']} ({data[0]['reg_no']})")
        else:
            print(f"✗ Failed: {resp.status_code} {resp.text}")

        # 2. Get Students (EEE) - New Dept
        print("\nTesting GET /api/students?dept=EEE")
        resp = requests.get(f"{base_url}/api/students?dept=EEE", headers=headers)
        if resp.status_code == 200:
            data = resp.json()
            print(f"✓ Success. Retrieved {len(data)} EEE students.")
            if len(data) > 0:
                print(f"  Sample: {data[0]['name']} ({data[0]['reg_no']})")
        else:
            print(f"✗ Failed: {resp.status_code} {resp.text}")

        # 3. Get Class Activities (CSE)
        print("\nTesting GET /api/activities/class/CSE/2/A")
        resp = requests.get(f"{base_url}/api/activities/class/CSE/2/A", headers=headers)
        if resp.status_code == 200:
            data = resp.json()
            print(f"✓ Success. Retrieved {len(data)} activity records.")
        else:
            print(f"✗ Failed: {resp.status_code} {resp.text}")

    except requests.exceptions.ConnectionError:
        print("✗ Could not connect to backend server. Is it running?")

if __name__ == "__main__":
    verify_database()
    verify_api()
