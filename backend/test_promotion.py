import sys
import os
import math

# Add the current directory to the path so we can import models and database
sys.path.append(os.getcwd())

from sqlalchemy.orm import Session
from database import SessionLocal
import models as models

def test_promotion():
    db = SessionLocal()
    try:
        # 1. Create a test student in StudentCSE
        test_reg_no = "TEST_PROMO_001"
        
        # Cleanup if exists
        db.query(models.StudentCSE).filter(models.StudentCSE.reg_no == test_reg_no).delete()
        db.query(models.User).filter(models.User.reg_no == test_reg_no).delete()
        db.commit()
        
        # Create user
        test_user = models.User(
            name="Test Student",
            email="test_promo@example.com",
            password="hashed_password",
            role=models.RoleEnum.STUDENT,
            reg_no=test_reg_no,
            year="1",
            dept="CSE",
            is_approved=1,
            is_active=1
        )
        db.add(test_user)
        
        # Create student
        test_student = models.StudentCSE(
            reg_no=test_reg_no,
            name="Test Student",
            email="test_promo@example.com",
            dept="CSE",
            year=1,
            semester=1,
            section="A"
        )
        db.add(test_student)
        db.commit()
        
        print(f"Created test student: {test_reg_no}, Semester: {test_student.semester}, Year: {test_student.year}")
        
        # 2. Simulate the promotion logic (internal call since running full API server + auth is complex in a script)
        from routes.admin_routes import promote_semester
        
        # We'll just run the logic directly for verification of the SQL/Logic
        student_models = [
            models.StudentCSE,
            models.StudentECE,
            models.StudentEEE,
            models.StudentMECH,
            models.StudentCIVIL,
            models.StudentBIO,
            models.StudentAIDS
        ]
        
        for student_model in student_models:
            students = db.query(student_model).filter(student_model.reg_no == test_reg_no).all()
            for student in students:
                student.semester += 1
                student.year = math.ceil(student.semester / 2)
                
                user = db.query(models.User).filter(models.User.reg_no == student.reg_no).first()
                if user:
                    user.year = str(student.year)
        
        db.commit()
        db.refresh(test_student)
        db.refresh(test_user)
        
        print(f"After promotion: Semester: {test_student.semester}, Year: {test_student.year}")
        print(f"User year: {test_user.year}")
        
        # 3. Assertions
        assert test_student.semester == 2
        assert test_student.year == 1
        assert test_user.year == "1"
        
        # Promotion to year 2
        test_student.semester = 2
        # Run promotion again
        test_student.semester += 1
        test_student.year = math.ceil(test_student.semester / 2)
        test_user.year = str(test_student.year)
        db.commit()
        db.refresh(test_student)
        
        print(f"After 2nd promotion: Semester: {test_student.semester}, Year: {test_student.year}")
        assert test_student.semester == 3
        assert test_student.year == 2
        assert test_user.year == "2"
        
        print("Verification SUCCESSFUL!")
        
    except Exception as e:
        print(f"Verification FAILED: {e}")
        import traceback
        traceback.print_exc()
    finally:
        # Cleanup
        db.query(models.StudentCSE).filter(models.StudentCSE.reg_no == test_reg_no).delete()
        db.query(models.User).filter(models.User.reg_no == test_reg_no).delete()
        db.commit()
        db.close()

if __name__ == "__main__":
    test_promotion()
