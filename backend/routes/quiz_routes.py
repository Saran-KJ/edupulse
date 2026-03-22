from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from auth import get_current_user
from models import (
    User, QuizQuestion, StudentQuizAttempt, PersonalizedLearningPlan,
    StudentCSE, StudentECE, StudentEEE, StudentMECH, StudentCIVIL, StudentBIO, StudentAIDS
)
import schemas
from gemini_service import generate_quiz_questions, generate_assessment_quiz
from typing import List, Dict

router = APIRouter(prefix="/api/quiz", tags=["Quiz"])

# Same model mapping as in learning_routes.py
STUDENT_MODEL_MAP = {
    'CSE': StudentCSE, 'ECE': StudentECE, 'EEE': StudentEEE,
    'MECH': StudentMECH, 'CIVIL': StudentCIVIL, 'BIO': StudentBIO, 'AIDS': StudentAIDS,
}

def _get_student(db: Session, current_user: User):
    """Helper to retrieve student record from department table."""
    student_model = STUDENT_MODEL_MAP.get(current_user.dept)
    if not student_model:
        raise HTTPException(status_code=404, detail="Student department not found")
    student = db.query(student_model).filter(student_model.email == current_user.email).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")
    return student

@router.get("/generate", response_model=schemas.QuizGenerationResponse)
def get_quiz(
    subject_name: str,
    unit_number: int,
    risk_level: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Fetches an existing quiz from the database or generates a new one using Gemini AI.
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access quizzes")

    difficulty_map = {
        "HIGH": "Basic",
        "MEDIUM": "Moderate",
        "LOW": "Advanced"
    }
    difficulty = difficulty_map.get(risk_level.upper(), "Moderate")

    # 1. Check if quiz already exists in database for this subject, unit, and difficulty
    print(f"DEBUG: Checking existing quiz for {subject_name} Unit {unit_number}...")
    existing_questions = db.query(QuizQuestion).filter(
        QuizQuestion.subject == subject_name,
        QuizQuestion.unit == unit_number,
        QuizQuestion.difficulty_level == difficulty
    ).all()
    print(f"DEBUG: Found {len(existing_questions)} existing questions.")

    if existing_questions:
        return {
            "subject": subject_name,
            "unit": unit_number,
            "risk_level": risk_level,
            "total_questions": len(existing_questions),
            "quiz": existing_questions
        }

    # 2. Generate new quiz if not found
    print(f"DEBUG: No existing quiz. Generating new quiz for {subject_name} Unit {unit_number} ({difficulty})...")
    raw_quiz = generate_quiz_questions(subject_name, unit_number, risk_level)
    
    if not raw_quiz:
        print("ERROR: generate_quiz_questions returned empty list or None")
        raise HTTPException(status_code=500, detail="Failed to generate quiz questions")

    print(f"DEBUG: Processing {len(raw_quiz)} questions from AI...")
    if len(raw_quiz) > 0:
        print(f"DEBUG: Sample question skip keys: {list(raw_quiz[0].keys())}")

    # 3. Save to database
    db_questions = []
    for q in raw_quiz:
        db_q = QuizQuestion(
            subject=subject_name,
            unit=unit_number,
            question=q.get("question", ""),
            option_a=q.get("option_a", ""),
            option_b=q.get("option_b", ""),
            option_c=q.get("option_c", ""),
            option_d=q.get("option_d", ""),
            correct_answer=q.get("correct_answer", ""),
            difficulty_level=difficulty
        )
        db.add(db_q)
        db_questions.append(db_q)
    
    try:
        db.commit()
        print("✓ Quiz successfully saved to database")
    except Exception as e:
        db.rollback()
        print(f"❌ Database Error during quiz save: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    for q in db_questions:
        db.refresh(q)

    return {
        "subject": subject_name,
        "unit": unit_number,
        "risk_level": risk_level,
        "total_questions": len(db_questions),
        "quiz": db_questions
    }

@router.get("/assessment/generate", response_model=schemas.QuizGenerationResponse)
def get_assessment_quiz(
    subject_name: str,
    unit_number: int,
    assessment_type: str,
    risk_level: str = "MEDIUM",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate mixed-type quiz for scheduled assessments (SlipTest, CIA, ModelExam).
    
    Question mix by assessment type:
    - SlipTest: 20 questions (30% MCQ, 40% MCS, 30% NAT)
    - CIA: 40 questions (25% MCQ, 50% MCS, 25% NAT)
    - ModelExam: 50 questions (30% MCQ, 40% MCS, 30% NAT)
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access quizzes")
    
    if assessment_type not in ["SlipTest", "CIA", "ModelExam"]:
        raise HTTPException(status_code=400, detail="Invalid assessment type. Use: SlipTest, CIA, ModelExam")
    
    difficulty_map = {
        "HIGH": "Basic",
        "MEDIUM": "Moderate",
        "LOW": "Advanced"
    }
    difficulty = difficulty_map.get(risk_level.upper(), "Moderate")
    
    # 1. Check if assessment quiz already exists in database
    print(f"DEBUG: Checking existing assessment quiz for {subject_name} Unit {unit_number} ({assessment_type})...")
    existing_questions = db.query(QuizQuestion).filter(
        QuizQuestion.subject == subject_name,
        QuizQuestion.unit == unit_number,
        QuizQuestion.difficulty_level == difficulty,
        QuizQuestion.assessment_type == assessment_type
    ).all()
    print(f"DEBUG: Found {len(existing_questions)} existing assessment questions.")
    
    if existing_questions:
        return {
            "subject": subject_name,
            "unit": unit_number,
            "risk_level": risk_level,
            "total_questions": len(existing_questions),
            "quiz": existing_questions
        }
    
    # 2. Generate new assessment quiz
    print(f"DEBUG: Generating new assessment quiz: {assessment_type} for {subject_name} Unit {unit_number}...")
    raw_quiz = generate_assessment_quiz(subject_name, unit_number, assessment_type, risk_level)
    
    if not raw_quiz:
        print("ERROR: generate_assessment_quiz returned empty list")
        raise HTTPException(status_code=500, detail="Failed to generate assessment quiz")
    
    print(f"DEBUG: Processing {len(raw_quiz)} questions from AI...")
    
    # 3. Save to database
    db_questions = []
    for q in raw_quiz:
        db_q = QuizQuestion(
            subject=subject_name,
            unit=unit_number,
            question=q.get("question", ""),
            option_a=q.get("option_a"),  # Can be None for NAT
            option_b=q.get("option_b"),
            option_c=q.get("option_c"),
            option_d=q.get("option_d"),
            correct_answer=q.get("correct_answer", ""),
            difficulty_level=difficulty,
            question_type=q.get("question_type", "MCQ"),
            assessment_type=assessment_type
        )
        db.add(db_q)
        db_questions.append(db_q)
    
    try:
        db.commit()
        print(f"SUCCESS: Saved {len(db_questions)} assessment questions to database")
    except Exception as e:
        db.rollback()
        print(f"ERROR during assessment quiz save: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    
    for q in db_questions:
        db.refresh(q)
    
    return {
        "subject": subject_name,
        "unit": unit_number,
        "risk_level": risk_level,
        "total_questions": len(db_questions),
        "quiz": db_questions
    }

@router.post("/submit", response_model=schemas.QuizAttemptResponse)
def submit_quiz(
    submission: schemas.QuizAttemptSubmission,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Submits a quiz attempt, calculates the score, and stores the result.
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can submit quizzes")

    total_questions = len(submission.answers)
    if total_questions == 0:
        raise HTTPException(status_code=400, detail="No answers submitted")

    student = _get_student(db, current_user)
    correct_count = 0
    
    # Verify answers
    for q_id_str, selected_option in submission.answers.items():
        try:
            q_id = int(q_id_str)
            question = db.query(QuizQuestion).filter(QuizQuestion.id == q_id).first()
            if question and question.correct_answer.strip().lower() == selected_option.strip().lower():
                correct_count += 1
        except ValueError:
            continue
            
    wrong_count = total_questions - correct_count
    score_percentage = (correct_count / total_questions) * 100

    # Store attempt
    attempt = StudentQuizAttempt(
        reg_no=student.reg_no,
        subject=submission.subject,
        unit=submission.unit,
        total_questions=total_questions,
        correct_answers=correct_count,
        wrong_answers=wrong_count,
        score=score_percentage,
        risk_level=submission.risk_level,
        scheduled_quiz_id=submission.scheduled_quiz_id
    )
    db.add(attempt)
    db.flush() # Flush to let the ML service query it immediately

    # Run the Early Risk Prediction using ML Logistic Regression
    from ml_service import ml_service
    prediction_result = ml_service.predict_early_risk(db, student.reg_no, submission.subject)
    
    # Alert System
    if prediction_result['risk_level'] == "High":
        from models import AcademicAlert
        alert_msg = f"Your academic performance indicates a high risk in {submission.subject}. Please follow the recommended learning plan."
        alert = AcademicAlert(
            reg_no=student.reg_no,
            subject=submission.subject,
            message=alert_msg,
            risk_level="High",
            probability=prediction_result['probability']
        )
        db.add(alert)
        
    db.commit()

    # Old Rule-based update logic for learning plan fallback
    if score_percentage >= 80:
        plan = db.query(PersonalizedLearningPlan).filter(
            PersonalizedLearningPlan.reg_no == student.reg_no,
            PersonalizedLearningPlan.subject_code == submission.subject,
            PersonalizedLearningPlan.is_active == 1
        ).first()
        if plan:
            if plan.risk_level == "High":
                plan.risk_level = "Medium"
                db.commit()
            elif plan.risk_level == "Medium":
                plan.risk_level = "Low"
                plan.pending_choice = True
                db.commit()

    return {
        "total_questions": total_questions,
        "correct_answers": correct_count,
        "wrong_answers": wrong_count,
        "score": score_percentage,
        "status": "success",
        "risk_probability": prediction_result.get('probability', 0)
    }
