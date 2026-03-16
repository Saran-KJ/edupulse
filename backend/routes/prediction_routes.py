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
