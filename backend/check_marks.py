from sqlalchemy.orm import Session
from database import SessionLocal
from models import User, Mark
import sys

def check_data():
    db = SessionLocal()
    print("--- Users (Class Advisors) ---")
    try:
        users = db.query(User).filter(User.role == 'class_advisor').all()
        if not users:
            print("No Class Advisors found.")
        else:
            print(f"{'ID':<4} | {'Name':<20} | {'Email':<25} | {'Dept':<6} | {'Year':<5} | {'Sec':<5}")
            print("-" * 80)
            for user in users:
                print(f"{user.user_id:<4} | {user.name:<20} | {user.email:<25} | {user.dept:<6} | {user.year:<5} | {user.section:<5}")

        print("\n--- Recent Mark Entries ---")
        marks = db.query(Mark).order_by(Mark.id.desc()).limit(5).all()
        if marks:
            print(f"{'ID':<4} | {'Reg No':<12} | {'Sub':<8} | {'Dept':<6} | {'Year':<5} | {'Sec':<5} | {'Sem':<3}")
            print("-" * 80)
            for mark in marks:
                print(f"{mark.id:<4} | {mark.reg_no:<12} | {mark.subject_code:<8} | {mark.dept:<6} | {mark.year:<5} | {mark.section:<5} | {mark.semester:<3}")
            
    except Exception as e:
        print(f"Error querying database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_data()
