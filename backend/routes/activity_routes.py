from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from database import get_db
import models
import schemas
import auth

router = APIRouter(prefix="/api/activities", tags=["Activities"])

@router.post("", response_model=schemas.ActivityResponse)
async def create_activity(
    activity: schemas.ActivityCreate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL
    ]))
):
    db_activity = models.Activity(**activity.dict())
    db.add(db_activity)
    db.commit()
    db.refresh(db_activity)
    return db_activity

@router.get("", response_model=List[schemas.ActivityResponse])
async def get_activities(
    skip: int = 0,
    limit: int = 100,
    activity_type: Optional[models.ActivityTypeEnum] = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    query = db.query(models.Activity)
    
    if activity_type:
        query = query.filter(models.Activity.activity_type == activity_type)
    
    activities = query.offset(skip).limit(limit).all()
    return activities

@router.get("/{activity_id}", response_model=schemas.ActivityResponse)
async def get_activity(
    activity_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    activity = db.query(models.Activity).filter(
        models.Activity.activity_id == activity_id
    ).first()
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
    return activity

@router.put("/{activity_id}", response_model=schemas.ActivityResponse)
async def update_activity(
    activity_id: int,
    activity_update: schemas.ActivityUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL
    ]))
):
    activity = db.query(models.Activity).filter(
        models.Activity.activity_id == activity_id
    ).first()
    
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
        
    if activity_update.activity_name is not None:
        activity.activity_name = activity_update.activity_name
    if activity_update.activity_type is not None:
        activity.activity_type = activity_update.activity_type
    if activity_update.level is not None:
        activity.level = activity_update.level
    if activity_update.activity_date is not None:
        activity.activity_date = activity_update.activity_date
    if activity_update.description is not None:
        activity.description = activity_update.description
        
    db.commit()
    db.refresh(activity)
    return activity

@router.post("/participation", response_model=schemas.ActivityParticipationResponse)
async def create_participation(
    participation: schemas.ActivityParticipationCreate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL
    ]))
):
    db_participation = models.ActivityParticipation(**participation.dict())
    db.add(db_participation)
    db.commit()
    db.refresh(db_participation)
    return db_participation

@router.get("/participation/student/{student_id}", response_model=List[schemas.ActivityParticipationResponse])
async def get_student_participations(
    student_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    participations = db.query(models.ActivityParticipation).filter(
        models.ActivityParticipation.student_id == student_id
    ).all()
    return participations

@router.delete("/participation/{participation_id}")
async def delete_participation(
    participation_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.PRINCIPAL
    ]))
):
    participation = db.query(models.ActivityParticipation).filter(
        models.ActivityParticipation.participation_id == participation_id
    ).first()
    
    if not participation:
        raise HTTPException(status_code=404, detail="Participation not found")
        
    db.delete(participation)
    db.commit()
    return {"message": "Participation deleted successfully"}

@router.put("/participation/{participation_id}", response_model=schemas.ActivityParticipationResponse)
async def update_participation(
    participation_id: int,
    update_data: schemas.ActivityParticipationUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.PRINCIPAL
    ]))
):
    participation = db.query(models.ActivityParticipation).filter(
        models.ActivityParticipation.participation_id == participation_id
    ).first()
    
    if not participation:
        raise HTTPException(status_code=404, detail="Participation not found")
        
    if update_data.role is not None:
        participation.role = update_data.role
    if update_data.achievement is not None:
        participation.achievement = update_data.achievement
        
    db.commit()
    db.refresh(participation)
    return participation

    db.delete(db_activity)
    db.commit()
    return {"message": "Activity deleted successfully"}

def get_student_model(dept: str):
    if not dept: return None
    dept = dept.upper()
    if dept == 'CSE': return models.StudentCSE
    if dept == 'ECE': return models.StudentECE
    if dept == 'EEE': return models.StudentEEE
    if dept == 'MECH': return models.StudentMECH
    if dept == 'CIVIL': return models.StudentCIVIL
    if dept == 'BIO.TECH': return models.StudentBIO
    if dept == 'AIDS': return models.StudentAIDS
    return None

@router.get("/class/{dept}/{year}/{section}", response_model=List[schemas.StudentWithActivities])
async def get_class_activities(
    dept: str, # Changed from dept_id
    year: int,
    section: str,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.HOD,
        models.RoleEnum.PRINCIPAL
    ]))
):
    # Get the correct student model for the department
    student_model = get_student_model(dept)
    if not student_model:
        raise HTTPException(status_code=400, detail="Invalid department")

    # 1. Get all students in this class
    students = db.query(student_model).filter(
        student_model.year == year,
        student_model.section == section
    ).all()
    
    result = []
    for student in students:
        # 2. Get participations for each student using reg_no
        participations = db.query(models.ActivityParticipation).options(
            joinedload(models.ActivityParticipation.activity)
        ).filter(
            models.ActivityParticipation.reg_no == student.reg_no
        ).all()
        
        result.append({
            "student": student,
            "activities": participations
        })
        
    return result
