from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models
import schemas
import auth
from ml_service import ml_service
from gemini_service import generate_quiz_questions

router = APIRouter(prefix="/api/predict", tags=["ML Prediction"])

@router.post("/risk", response_model=schemas.RiskPredictionResponse)
async def predict_student_risk(
    request: schemas.RiskPredictionRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    # ML Service handles the lookup internally now using reg_no
    try:
        # Get prediction
        prediction_result = ml_service.predict_risk(db, request.reg_no)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Error predicting risk for {request.reg_no}: {str(e)}")
    
    # Save prediction to database
    db_prediction = ml_service.save_prediction(db, request.reg_no, prediction_result)
    if not db_prediction:
         raise HTTPException(status_code=500, detail="Failed to save risk prediction")
    
    # Clear overall study strategy cache for the student
    from routes.learning_routes import _get_student_by_reg, generate_plans_for_student_task, STUDENT_MODEL_MAP
    
    # Find student across all depts to clear cache
    student = None
    for dept in STUDENT_MODEL_MAP.keys():
        try:
            student = _get_student_by_reg(db, request.reg_no, dept)
            if student:
                student.overall_study_strategy = None
                db.commit()
                break # Found and cleared
        except:
            continue

    # Trigger personalized learning plan regeneration in background
    background_tasks.add_task(generate_plans_for_student_task, request.reg_no)
    
    return db_prediction

@router.get("/{reg_no}", response_model=schemas.RiskPredictionResponse)
async def predict_student_risk_get(
    reg_no: str,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """
    Trigger risk prediction for a student via GET request (for easy testing).
    """
    try:
        # Get prediction
        prediction_result = ml_service.predict_risk(db, reg_no)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Error predicting risk for {reg_no}: {str(e)}")
    
    # Save prediction to database
    db_prediction = ml_service.save_prediction(db, reg_no, prediction_result)
    if not db_prediction:
         raise HTTPException(status_code=500, detail="Failed to save risk prediction")
    
    # Clear overall study strategy cache for the student
    from routes.learning_routes import _get_student_by_reg, generate_plans_for_student_task, STUDENT_MODEL_MAP
    
    # Find student across all depts to clear cache
    student = None
    for dept in STUDENT_MODEL_MAP.keys():
        try:
            student = _get_student_by_reg(db, reg_no, dept)
            if student:
                student.overall_study_strategy = None
                db.commit()
                break
        except:
            continue

    # Trigger personalized learning plan regeneration in background
    background_tasks.add_task(generate_plans_for_student_task, reg_no)
    
    return db_prediction

@router.get("/at-risk-students", response_model=List[schemas.RiskPredictionResponse])
async def get_at_risk_students(
    risk_level: models.RiskLevelEnum = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    # Get latest predictions for each student
    from sqlalchemy import func
    
    subquery = db.query(
        models.RiskPrediction.reg_no,
        func.max(models.RiskPrediction.prediction_id).label('max_id')
    ).group_by(models.RiskPrediction.reg_no).subquery()
    
    query = db.query(models.RiskPrediction).join(
        subquery,
        models.RiskPrediction.prediction_id == subquery.c.max_id
    )
    
    if risk_level:
        query = query.filter(models.RiskPrediction.risk_level == risk_level)
    else:
        # Default: show Medium and High risk students
        query = query.filter(
            models.RiskPrediction.risk_level.in_([models.RiskLevelEnum.MEDIUM, models.RiskLevelEnum.HIGH])
        )
    
    predictions = query.all()
    return predictions

@router.get("/history/{reg_no}", response_model=List[schemas.RiskPredictionResponse])
async def get_prediction_history(
    reg_no: str,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    predictions = db.query(models.RiskPrediction).filter(
        models.RiskPrediction.reg_no == reg_no
    ).order_by(models.RiskPrediction.prediction_date.desc()).all()
    
    return predictions

@router.post("/early-risk-quiz", response_model=schemas.QuizGenerationResponse)
async def get_early_risk_quiz(
    request: schemas.EarlyRiskQuizRequest,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """
    Generate an early risk assessment quiz for a student.
    
    This endpoint:
    1. Performs early risk prediction for the given subject
    2. Generates targeted quiz questions based on risk level
    3. Returns quiz appropriate for the student's risk level
    
    The quiz difficulty is tailored to help identify knowledge gaps early.
    """
    try:
        # Perform early risk prediction
        early_risk = ml_service.predict_early_risk(db, request.reg_no, request.subject_code)
        risk_level = early_risk['risk_level']
        
        print(f"DEBUG: Early risk for {request.reg_no} in {request.subject_code}: {risk_level}")
        print(f"DEBUG: Risk probability: {early_risk['probability']:.4f}")
        
    except Exception as e:
        raise HTTPException(
            status_code=400, 
            detail=f"Failed to compute early risk: {str(e)}"
        )
    
    # Generate quiz questions based on risk level
    try:
        quiz_questions = generate_quiz_questions(
            subject_name=request.subject_code,
            unit_number=request.unit_number,
            risk_level=risk_level
        )
        
        if not quiz_questions:
            raise HTTPException(
                status_code=500, 
                detail="Failed to generate quiz questions"
            )
        
        # Save quiz questions to database
        db_questions = []
        for q in quiz_questions:
            db_q = models.QuizQuestion(
                subject=request.subject_code,
                unit=request.unit_number,
                question=q.get("question", ""),
                option_a=q.get("option_a", ""),
                option_b=q.get("option_b", ""),
                option_c=q.get("option_c", ""),
                option_d=q.get("option_d", ""),
                correct_answer=q.get("correct_answer", ""),
                difficulty_level=risk_level,
                is_early_risk_quiz=1  # Mark as early risk quiz
            )
            db.add(db_q)
            db_questions.append(db_q)
        
        db.commit()
        
        # Return formatted response
        return {
            "subject": request.subject_code,
            "unit": request.unit_number,
            "risk_level": risk_level,
            "total_questions": len(db_questions),
            "quiz": db_questions,
            "early_risk_info": {
                "probability": early_risk['probability'],
                "features": early_risk.get('features_used', {})
            }
        }
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate early risk quiz: {str(e)}"
        )

@router.get("/early-risk/{reg_no}/{subject_code}")
async def get_student_early_risk(
    reg_no: str,
    subject_code: str,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """
    Get early risk assessment for a student in a specific subject.
    
    Returns:
    - Risk level (Low, Medium, High)
    - Risk probability score
    - Contributing factors
    - Recommendations
    """
    try:
        early_risk = ml_service.predict_early_risk(db, reg_no, subject_code)
        
        # Generate recommendations based on risk level
        risk_level = early_risk['risk_level']
        recommendations = {
            "High": [
                "Attend extra tutorials",
                "Focus on fundamental concepts",
                "Practice more quiz questions",
                "Schedule 1-on-1 sessions with faculty"
            ],
            "Medium": [
                "Review key concepts regularly",
                "Complete all assignments",
                "Participate in study groups",
                "Take practice quizzes"
            ],
            "Low": [
                "Continue current learning pace",
                "Challenge yourself with advanced topics",
                "Help peers with difficult concepts",
                "Explore project-based learning"
            ]
        }
        
        return {
            "reg_no": reg_no,
            "subject_code": subject_code,
            "risk_level": risk_level,
            "probability": early_risk['probability'],
            "probability_percentage": round(early_risk['probability'] * 100, 2),
            "features": early_risk.get('features_used', {}),
            "recommendations": recommendations.get(risk_level, []),
            "interpretation": {
                "High": "Student may struggle without additional support. Immediate intervention recommended.",
                "Medium": "Student shows some risk factors. Regular monitoring and targeted help suggested.",
                "Low": "Student is on track. Continue regular learning activities."
            }.get(risk_level, "")
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Failed to compute early risk: {str(e)}"
        )
