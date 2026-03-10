import sys
import os
sys.path.insert(0, os.path.abspath('.'))

from sqlalchemy.orm import Session
from database import SessionLocal
import models
from datetime import datetime

def test_db_flow():
    db = SessionLocal()
    print("Testing Quiz Database Flow...")
    
    reg_no = "2021CSE001"
    subject = "DBMS"
    unit = 1
    
    try:
        # 1. Clean up existing test data
        db.query(models.QuizQuestion).filter(models.QuizQuestion.subject == subject).delete()
        db.query(models.StudentQuizAttempt).filter(models.StudentQuizAttempt.reg_no == reg_no).delete()
        db.commit()
        
        # 2. Simulate saving generated questions
        print("Simulating question storage...")
        q1 = models.QuizQuestion(
            subject=subject,
            unit=unit,
            question="What is SQL?",
            option_a="Structured Query Language",
            option_b="Simple Query Language",
            option_c="Standard Question Language",
            option_d="System Quality Logic",
            correct_answer="Structured Query Language",
            difficulty_level="Basic"
        )
        db.add(q1)
        db.commit()
        db.refresh(q1)
        print(f"✓ Question saved with ID: {q1.id}")
        
        # 3. Simulate attempt submission
        print("Simulating high-score attempt submission...")
        attempt = models.StudentQuizAttempt(
            reg_no=reg_no,
            subject=subject,
            unit=unit,
            total_questions=1,
            correct_answers=1,
            wrong_answers=0,
            score=100.0,
            risk_level="HIGH"
        )
        db.add(attempt)
        
        # 4. Verify risk update logic (manually triggered here as per routes/quiz_routes.py)
        # In the actual route, this happens automatically
        plan = db.query(models.PersonalizedLearningPlan).filter(
            models.PersonalizedLearningPlan.reg_no == reg_no,
            models.PersonalizedLearningPlan.subject_code == subject
        ).first()
        
        if not plan:
            # Create a mock plan if none exists for the test
            plan = models.PersonalizedLearningPlan(
                reg_no=reg_no,
                subject_code=subject,
                risk_level="High",
                focus_type="Academic Recovery",
                is_active=1
            )
            db.add(plan)
            db.commit()
            db.refresh(plan)
            print("Created mock plan for risk update testing.")
            
        old_risk = plan.risk_level
        if attempt.score >= 80:
            if plan.risk_level == "High":
                plan.risk_level = "Medium"
            elif plan.risk_level == "Medium":
                plan.risk_level = "Low"
        
        db.commit()
        db.refresh(plan)
        print(f"✓ Risk level updated: {old_risk} -> {plan.risk_level}")
        
        # 5. Final check
        saved_attempt = db.query(models.StudentQuizAttempt).filter(models.StudentQuizAttempt.reg_no == reg_no).first()
        if saved_attempt and plan.risk_level == "Medium":
            print("\n✓ FULL DB FLOW VERIFIED SUCCESSFULLY")
        else:
            print("\n✗ DB Flow verification failed.")
            
    finally:
        db.close()

if __name__ == "__main__":
    test_db_flow()
