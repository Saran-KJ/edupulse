from database import SessionLocal
from models import Mark

def update_grades():
    db = SessionLocal()
    try:
        marks = db.query(Mark).all()
        grades = ['S', 'A', 'B']
        
        for i, mark in enumerate(marks):
            mark.university_result_grade = grades[i % len(grades)]
            print(f"Updated Mark ID {mark.id} with grade {mark.university_result_grade}")
            
        db.commit()
        print("Grades updated successfully.")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    update_grades()
