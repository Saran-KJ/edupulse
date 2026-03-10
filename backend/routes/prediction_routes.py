from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models
import schemas
import auth
from ml_service import ml_service

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
        raise HTTPException(status_code=404, detail=f"Student not found or error predicting: {str(e)}")
    
    # Save prediction to database
    db_prediction = models.RiskPrediction(
        reg_no=request.reg_no,
        risk_level=prediction_result['risk_level'],
        risk_score=prediction_result['risk_score'],
        attendance_percentage=prediction_result['attendance_percentage'],
        internal_avg=prediction_result['internal_avg'],
        external_gpa=prediction_result['external_gpa'],
        activity_count=prediction_result['activity_count'],
        backlog_count=prediction_result['backlog_count'],
        reasons=prediction_result['reasons']
    )
    db.add(db_prediction)
    db.commit()
    db.refresh(db_prediction)
    
    # Clear overall study strategy cache for the student
    from routes.learning_routes import _get_student, generate_plans_for_student_task
    student = _get_student(db, current_user)
    if student:
        student.overall_study_strategy = None
        db.commit()

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
        raise HTTPException(status_code=404, detail=f"Student not found or error predicting: {str(e)}")
    
    # Save prediction to database
    db_prediction = models.RiskPrediction(
        reg_no=reg_no,
        risk_level=prediction_result['risk_level'],
        risk_score=prediction_result['risk_score'],
        attendance_percentage=prediction_result['attendance_percentage'],
        internal_avg=prediction_result['internal_avg'],
        external_gpa=prediction_result['external_gpa'],
        activity_count=prediction_result['activity_count'],
        backlog_count=prediction_result['backlog_count'],
        reasons=prediction_result['reasons']
    )
    db.add(db_prediction)
    db.commit()
    db.refresh(db_prediction)
    
    # Clear overall study strategy cache for the student
    from routes.learning_routes import _get_student, generate_plans_for_student_task
    student = _get_student(db, current_user)
    if student:
        student.overall_study_strategy = None
        db.commit()

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
