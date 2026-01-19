from database import SessionLocal
from models import Mark

def clear_grades():
    db = SessionLocal()
    try:
        marks = db.query(Mark).all()
        print(f"Found {len(marks)} marks. Clearing grades...")
        
        for mark in marks:
            mark.university_result_grade = None
            
        db.commit()
        print("University grades cleared successfully.")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    clear_grades()
