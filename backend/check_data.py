from database import SessionLocal
import models
from sqlalchemy import func

db = SessionLocal()

def check_data():
    print("Checking data for CSE Year 2 Section A...")
    
    # Check Students
    dept_id = 1 # CSE
    year = 2
    section = 'A'
    
    students = db.query(models.Student).filter(
        models.Student.dept_id == dept_id,
        models.Student.year == year,
        models.Student.section == section
    ).all()
    print(f"Students found: {len(students)}")
    for s in students:
        print(f" - {s.reg_no}: {s.name}")

    # Check Attendance
    attendance = db.query(models.Attendance).filter(
        models.Attendance.dept == 'CSE',
        models.Attendance.year == year,
        models.Attendance.section == section
    ).all()
    print(f"Attendance records found: {len(attendance)}")
    
    # Check Marks
    marks = db.query(models.Mark).filter(
        models.Mark.reg_no.in_([s.reg_no for s in students])
    ).all()
    print(f"Marks found: {len(marks)}")

if __name__ == "__main__":
    check_data()
