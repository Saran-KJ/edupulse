from sqlalchemy.orm import Session
from database import SessionLocal
import models

def update_student_sections():
    db = SessionLocal()
    try:
        students = db.query(models.Student).all()
        for student in students:
            student.section = 'A'
        db.commit()
        print(f"Updated {len(students)} students with section 'A'.")
    except Exception as e:
        print(f"Error updating students: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    update_student_sections()
