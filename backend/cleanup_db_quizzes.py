from sqlalchemy.orm import Session
from database import SessionLocal
from models import QuizQuestion

def cleanup_quizzes():
    db = SessionLocal()
    try:
        # Subject and Unit from the screenshot/logs
        subject = "Computer Networks"
        unit = 1
        
        print(f"Cleaning up questions for {subject} Unit {unit}...")
        
        # Delete existing questions for this quiz to force regeneration
        deleted_count = db.query(QuizQuestion).filter(
            QuizQuestion.subject == subject,
            QuizQuestion.unit == unit
        ).delete()
        
        db.commit()
        print(f"Successfully deleted {deleted_count} questions.")
        
    except Exception as e:
        db.rollback()
        print(f"Error during cleanup: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    cleanup_quizzes()
