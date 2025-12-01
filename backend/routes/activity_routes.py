from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
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

@router.post("/participation", response_model=schemas.ActivityParticipationResponse)
async def create_participation(
    participation: schemas.ActivityParticipationCreate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
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

@router.delete("/{activity_id}")
async def delete_activity(
    activity_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([models.RoleEnum.ADMIN]))
):
    db_activity = db.query(models.Activity).filter(
        models.Activity.activity_id == activity_id
    ).first()
    if not db_activity:
        raise HTTPException(status_code=404, detail="Activity not found")
    
    db.delete(db_activity)
    db.commit()
    return {"message": "Activity deleted successfully"}
