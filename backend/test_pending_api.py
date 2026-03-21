import requests
import json

def test_pending_quizzes():
    # We need a token. I'll try to find one from the logs or just use a mock approach if I can't.
    # Actually, I'll just run a script that calls the function directly with a mock user.
    from sqlalchemy.orm import Session
    from database import SessionLocal
    import models
    from routes.student_routes import get_pending_quizzes
    from fastapi import Request
    
    db = SessionLocal()
    try:
        # Mock a user - based on logs, student with reg_no 521456321
        reg_no = '521456321'
        # Get the actual user object
        user = db.query(models.User).filter(models.User.reg_no == reg_no).first()
        if not user:
            print(f"User {reg_no} not found")
            return

        print(f"Testing for user: {user.name} ({user.reg_no})")
        
        # Call the function directly
        result = get_pending_quizzes(db, user)
        print("Pending Quizzes Result:")
        print(json.dumps(result, indent=2))
        
    finally:
        db.close()

if __name__ == "__main__":
    test_pending_quizzes()
