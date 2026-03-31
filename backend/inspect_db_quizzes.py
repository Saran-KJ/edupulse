from sqlalchemy.orm import Session
from database import SessionLocal
from models import QuizQuestion

def inspect_quizzes():
    db = SessionLocal()
    try:
        subject = "Computer Networks"
        unit = 1
        
        questions = db.query(QuizQuestion).filter(
            QuizQuestion.subject == subject,
            QuizQuestion.unit == unit
        ).all()
        
        print(f"--- Inspection for {subject} Unit {unit} ---")
        print(f"Total found: {len(questions)}")
        
        for i, q in enumerate(questions):
            print(f"{i+1}. [ID: {q.id}] [Type: {q.question_type}] [Diff: {q.difficulty_level}]")
            print(f"   Q: {q.question}")
            print(f"   Options: A:{q.option_a}, B:{q.option_b}, C:{q.option_c}, D:{q.option_d}")
            print(f"   Correct: {q.correct_answer}")
            print("-" * 20)
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    inspect_quizzes()
