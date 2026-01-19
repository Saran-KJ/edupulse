from database import SessionLocal
from models import Mark

def check_marks():
    db = SessionLocal()
    try:
        marks = db.query(Mark).all()
        print(f"Total marks found: {len(marks)}")
        
        required_fields = ['reg_no', 'student_name', 'dept', 'year', 'section', 'semester', 'subject_code', 'subject_title']
        
        for mark in marks:
            missing = []
            for field in required_fields:
                val = getattr(mark, field)
                if val is None:
                    missing.append(field)
            
            if missing:
                print(f"WARNING: Mark ID {mark.id} missing fields: {missing}")
            
            print(f"ID: {mark.id}, Reg: {mark.reg_no}, Dept: {mark.dept}, Year: {mark.year}, Section: {mark.section}, Grade: {mark.university_result_grade}")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_marks()
