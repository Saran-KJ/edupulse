from sqlalchemy.orm import Session
from database import SessionLocal
import models

def check_class_advisors():
    db = SessionLocal()
    try:
        # Get all Class Advisor users
        advisors = db.query(models.User).filter(
            models.User.role == models.RoleEnum.CLASS_ADVISOR
        ).all()
        
        print("\n=== CLASS ADVISOR ACCOUNTS ===")
        for advisor in advisors:
            print(f"\nUser ID: {advisor.user_id}")
            print(f"Name: {advisor.name}")
            print(f"Email: {advisor.email}")
            print(f"Dept: {advisor.dept}")
            print(f"Year: {advisor.year}")
            print(f"Section: {advisor.section}")
            print("-" * 40)
            
        if not advisors:
            print("No Class Advisor accounts found.")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_class_advisors()
