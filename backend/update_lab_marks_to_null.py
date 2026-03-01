from database import SessionLocal
from models import Mark, Subject
from sqlalchemy import update

def remove_lab_marks():
    db = SessionLocal()
    try:
        # Get all lab subjects
        lab_subjects = db.query(Subject).filter(Subject.category == 'LAB').all()
        lab_subject_codes = [s.subject_code for s in lab_subjects]
        
        print(f"Found {len(lab_subject_codes)} lab subjects.")
        
        if not lab_subject_codes:
            print("No lab subjects found. Nothing to update.")
            return

        # Update marks for these subjects
        marks_to_update = db.query(Mark).filter(Mark.subject_code.in_(lab_subject_codes)).all()
        print(f"Found {len(marks_to_update)} mark entries for lab subjects. Updating internal marks to NULL...")

        for mark in marks_to_update:
            mark.assignment_1 = None
            mark.assignment_2 = None
            mark.assignment_3 = None
            mark.assignment_4 = None
            mark.assignment_5 = None
            mark.slip_test_1 = None
            mark.slip_test_2 = None
            mark.slip_test_3 = None
            mark.slip_test_4 = None
            mark.cia_1 = None
            mark.cia_2 = None
            mark.model = None

        db.commit()
        print("Successfully updated database: Removed internal marks for lab subjects.")
    except Exception as e:
        db.rollback()
        print(f"Error occurred: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    remove_lab_marks()
