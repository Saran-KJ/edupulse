from fastapi import APIRouter, Depends, HTTPException
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
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    # Check if student exists
    student = db.query(models.Student).filter(
        models.Student.student_id == request.student_id
    ).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Get prediction
    prediction_result = ml_service.predict_risk(db, request.student_id)
    
    # Save prediction to database
    db_prediction = models.RiskPrediction(
        student_id=request.student_id,
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
        models.RiskPrediction.student_id,
        func.max(models.RiskPrediction.prediction_id).label('max_id')
    ).group_by(models.RiskPrediction.student_id).subquery()
    
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

@router.get("/history/{student_id}", response_model=List[schemas.RiskPredictionResponse])
async def get_prediction_history(
    student_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    predictions = db.query(models.RiskPrediction).filter(
        models.RiskPrediction.student_id == student_id
    ).order_by(models.RiskPrediction.prediction_date.desc()).all()
    
    return predictions
