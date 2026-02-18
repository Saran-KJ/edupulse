from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from database import get_db
from models import User, LearningResource, StudentBase, StudentCSE, StudentECE, StudentEEE, StudentMECH, StudentCIVIL, StudentBIO, StudentAIDS, StudentLearningProgress
from auth import get_current_user
from ml_service import ml_service
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()

class LearningResourceResponse(BaseModel):
    resource_id: int
    title: str
    description: Optional[str] = None
    url: str
    type: str
    tags: Optional[str] = None
    is_completed: bool = False
    
    class Config:
        from_attributes = True

class ProgressUpdate(BaseModel):
    resource_id: int
    completed: bool

@router.get("/recommendations", response_model=Dict[str, Any])
def get_learning_recommendations(
    subject_code: Optional[str] = None,
    language: str = "English", # Added language parameter
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can get recommendations")

    # Get student details to find department
    student_model_map = {
        'CSE': StudentCSE,
        'ECE': StudentECE,
        'EEE': StudentEEE,
        'MECH': StudentMECH,
        'CIVIL': StudentCIVIL,
        'BIO': StudentBIO,
        'AIDS': StudentAIDS
    }
    
    student_model = student_model_map.get(current_user.dept)
    if not student_model:
        raise HTTPException(status_code=404, detail="Student department not found")
        
    student = db.query(student_model).filter(student_model.email == current_user.email).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")

    # Get risk prediction
    risk_level = 'Low' # Default
    risk_basis = 'General'
    risk_score = 0
    
    if subject_code:
        # Subject-specific risk (Personalized)
        subject_risk = ml_service.calculate_subject_risk(db, student.reg_no, subject_code)
        risk_level = subject_risk['risk_level']
        risk_score = subject_risk['score']
        risk_basis = f"Subject Risk: {risk_level} ({subject_risk['basis']})"
    else:
        # Overall risk
        risk_data = ml_service.predict_risk(db, student.reg_no)
        risk_level = risk_data.get('risk_level', 'Low')
        risk_basis = f"Overall Risk: {risk_level}"
    
    # Query resources
    query = db.query(LearningResource)
    # Filter by department or general resources
    query = query.filter((LearningResource.dept == current_user.dept) | (LearningResource.dept == None))
    
    # Filter by Language
    if language and language != "All":
        query = query.filter(LearningResource.language == language)
    
    resources = query.all()
    
    # Get completed resources
    completed_records = db.query(StudentLearningProgress).filter(
        StudentLearningProgress.reg_no == student.reg_no,
        StudentLearningProgress.completed == 1
    ).all()
    completed_ids = {record.resource_id for record in completed_records}
    
    filtered_resources = []
    for res in resources:
        res_tags = (res.tags or "").lower()
        should_include = True
        
        # Risk level filter
        if res.min_risk_level:
            risk_map = {'Low': 1, 'Medium': 2, 'High': 3}
            student_risk_val = risk_map.get(risk_level, 1)
            res_risk_val = risk_map.get(res.min_risk_level, 1)
            
            if student_risk_val < res_risk_val:
                should_include = False
        
        # Subject code filter (if provided)
        if subject_code and should_include:
            if subject_code.lower() not in res_tags:
                should_include = False
        
        if should_include:
            # Create response object with is_completed flag
            res_dict = {
                "resource_id": res.resource_id,
                "title": res.title,
                "description": res.description,
                "url": res.url,
                "type": res.type,
                "tags": res.tags,
                "is_completed": res.resource_id in completed_ids
            }
            filtered_resources.append(res_dict)
            
    # Calculate progress
    total_recommended = len(filtered_resources)
    total_completed = sum(1 for r in filtered_resources if r['is_completed'])
    progress_percentage = (total_completed / total_recommended * 100) if total_recommended > 0 else 0
    
    # Sorting Logic:
    # If High Risk -> Quizzes first
    if risk_level == "High":
        # Sort so that type='quiz' comes first
        filtered_resources.sort(key=lambda x: x['type'] != 'quiz') # False (0) comes before True (1), so quiz (False for != quiz) comes first? Wait.
        # x['type'] != 'quiz' is False if it IS a quiz. False < True. So Quiz comes first. Correct.
            
    return {
        "resources": filtered_resources,
        "risk_context": {
            "level": risk_level,
            "basis": risk_basis,
            "score": risk_score
        },
        "progress": {
            "total": total_recommended,
            "completed": total_completed,
            "percentage": progress_percentage
        }
    }

@router.post("/progress")
def update_progress(
    update: ProgressUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can update progress")
        
    # Get student reg_no
    student_model_map = {
        'CSE': StudentCSE,
        'ECE': StudentECE,
        'EEE': StudentEEE,
        'MECH': StudentMECH,
        'CIVIL': StudentCIVIL,
        'BIO': StudentBIO,
        'AIDS': StudentAIDS
    }
    student_model = student_model_map.get(current_user.dept)
    if not student_model:
        raise HTTPException(status_code=404, detail="Student department not found")
    student = db.query(student_model).filter(student_model.email == current_user.email).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")
        
    # Check if record exists
    progress = db.query(StudentLearningProgress).filter(
        StudentLearningProgress.reg_no == student.reg_no,
        StudentLearningProgress.resource_id == update.resource_id
    ).first()
    
    if progress:
        progress.completed = 1 if update.completed else 0
        progress.completed_at = datetime.utcnow()
    else:
        progress = StudentLearningProgress(
            reg_no=student.reg_no,
            resource_id=update.resource_id,
            completed=1 if update.completed else 0
        )
        db.add(progress)
        
    db.commit()
    return {"status": "success"}
