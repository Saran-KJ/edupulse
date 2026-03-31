import sys
import os

# Add the current directory to the path so we can import internal modules
sys.path.append(os.getcwd())

from database import SessionLocal
import models
import auth
from datetime import datetime

def seed_student():
    db = SessionLocal()
    try:
        # 1. Create/Update User record
        user = db.query(models.User).filter(models.User.email == "student@edupulse.com").first()
        if not user:
            print("Creating User student@edupulse.com...")
            user = models.User(
                name="Test Student",
                email="student@edupulse.com",
                password=auth.get_password_hash("student123"),
                role=models.RoleEnum.STUDENT,
                is_approved=1,
                is_active=1,
                reg_no="TEST001",
                dept="CSE",
                year="4",
                section="A"
            )
            db.add(user)
        else:
            print("Updating User student@edupulse.com...")
            user.password = auth.get_password_hash("student123")
            user.is_approved = 1
            user.is_active = 1
            user.dept = "CSE"
            user.role = models.RoleEnum.STUDENT

        # 2. Create/Update StudentCSE record
        student_profile = db.query(models.StudentCSE).filter(models.StudentCSE.email == "student@edupulse.com").first()
        if not student_profile:
            print("Creating StudentCSE profile...")
            student_profile = models.StudentCSE(
                reg_no="TEST001",
                name="Test Student",
                email="student@edupulse.com",
                phone="1234567890",
                dept="CSE",
                year=4,
                semester=8,
                section="A"
            )
            db.add(student_profile)
        else:
            print("StudentCSE profile already exists.")

        db.commit()
        print("Successfully seeded all data for student@edupulse.com.")

    except Exception as e:
        print(f"Error seeding student: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_student()
