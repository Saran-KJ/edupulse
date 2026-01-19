from database import SessionLocal
from models import Mark

def inspect_marks():
    db = SessionLocal()
    try:
        marks = db.query(Mark).all()
        print(f"Total marks: {len(marks)}")
        for m in marks:
            print(f"ID: {m.id}, Reg: {m.reg_no}, SubCode: '{m.subject_code}', SubTitle: '{m.subject_title}', Sem: {m.semester}, Grade: {m.university_result_grade}")
    finally:
        db.close()

if __name__ == "__main__":
    inspect_marks()
