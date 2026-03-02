from fastapi.testclient import TestClient
from main import app
from database import SessionLocal
import models
import schemas
import os
import sys

# Ensure backend root is on path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

client = TestClient(app)

def run_tests():
    db = SessionLocal()
    try:
        # 1. Ensure test user exists
        test_email = "test_otp_user@example.com"
        user = db.query(models.User).filter(models.User.email == test_email).first()
        if not user:
            user = models.User(
                name="Test API User",
                email=test_email,
                password="dummy_password",
                role=models.RoleEnum.STUDENT,
                is_approved=1,
                is_active=1
            )
            db.add(user)
            db.commit()

        print("--- Testing Request OTP ---")
        response = client.post("/api/auth/forgot-password/request-otp", json={"email": test_email})
        print(f"Status: {response.status_code}, Body: {response.json()}")
        
        if response.status_code == 200:
            print("--- Testing Verify OTP ---")
            reset = db.query(models.PasswordReset).filter(models.PasswordReset.email == test_email).first()
            if reset:
                otp_code = reset.otp
                print(f"Retrieved OTP from DB: {otp_code}")
                
                resp2 = client.post("/api/auth/forgot-password/verify-otp", json={"email": test_email, "otp": otp_code})
                print(f"Status: {resp2.status_code}, Body: {resp2.json()}")
                
                print("--- Testing Confirm Reset ---")
                resp3 = client.post("/api/auth/forgot-password/confirm", json={"email": test_email, "otp": otp_code, "new_password": "new_secure_pw123"})
                print(f"Status: {resp3.status_code}, Body: {resp3.json()}")
                
                reset_after = db.query(models.PasswordReset).filter(models.PasswordReset.email == test_email).first()
                if reset_after is None:
                    print("SUCCESS: OTP entry was successfully cleaned up after use.")
                else:
                    print("WARNING: OTP entry still exists in DB.")
            else:
                print("Failed to find OTP in database despite 200 OK.")
        else:
            print("Failed to request OTP. Check server logs or SMTP configuration.")
    except Exception as e:
        print(f"Error occurred: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    run_tests()
