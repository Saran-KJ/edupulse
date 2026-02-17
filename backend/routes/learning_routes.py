from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import User, LearningResource, StudentBase, StudentCSE, StudentECE, StudentEEE, StudentMECH, StudentCIVIL, StudentBIO, StudentAIDS
from auth import get_current_user
from ml_service import ml_service
from typing import List, Optional
from pydantic import BaseModel

router = APIRouter()

class LearningResourceResponse(BaseModel):
    resource_id: int
    title: str
    description: Optional[str] = None
    url: str
    type: str
    tags: Optional[str] = None
    
    class Config:
        from_attributes = True

@router.get("/recommendations", response_model=List[LearningResourceResponse])
def get_learning_recommendations(
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
    risk_data = ml_service.predict_risk(db, student.student_id)
    risk_level = risk_data.get('risk_level', 'Low')
    
    # Query resources
    # 1. General resources for everyone (dept is null)
    # 2. Dept specific resources
    # 3. Filter by risk level relevance
    
    query = db.query(LearningResource)
    
    # Filter by dept (match dept or generic)
    query = query.filter((LearningResource.dept == current_user.dept) | (LearningResource.dept == None))
    
    resources = query.all()
    
    # Filter in python for complex logic or refine query
    # Logic: 
    # - If Risk is High: Prioritize remedial/basics
    # - If Risk is Low: Prioritize advanced
    
    filtered_resources = []
    for res in resources:
        # Simple string matching in tags for demonstration
        res_tags = (res.tags or "").lower()
        
        should_include = True
        if res.min_risk_level:
            # Only show if student risk >= resource min risk
            # Risk levels: Low < Medium < High
            risk_map = {'Low': 1, 'Medium': 2, 'High': 3}
            student_risk_val = risk_map.get(risk_level, 1)
            res_risk_val = risk_map.get(res.min_risk_level, 1)
            
            if student_risk_val < res_risk_val:
                should_include = False
        
        if should_include:
            filtered_resources.append(res)
            
    return filtered_resources
