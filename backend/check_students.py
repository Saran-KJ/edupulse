from sqlalchemy.orm import Session
from database import SessionLocal
import models

def check_students():
    db = SessionLocal()
    try:
        # Get all students
        students = db.query(models.Student).all()
        
        print("\n=== ALL STUDENTS ===")
        for student in students:
            print(f"ID: {student.student_id} | Name: {student.name} | "
                  f"Dept: {student.dept_id} | Year: {student.year} | Section: {student.section}")
        
        print(f"\nTotal students: {len(students)}")
        
        # Check for Year 4, Section B students
        year4_b = db.query(models.Student).filter(
            models.Student.year == 4,
            models.Student.section == 'B'
        ).all()
        
        print(f"\n=== YEAR 4, SECTION B STUDENTS ===")
        if year4_b:
            for student in year4_b:
                print(f"Name: {student.name}")
        else:
            print("No students found for Year 4, Section B")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_students()
