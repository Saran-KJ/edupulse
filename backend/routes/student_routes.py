from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models
import schemas
import auth

router = APIRouter(prefix="/api/students", tags=["Students"])

@router.get("", response_model=List[schemas.StudentResponse])
async def get_students(
    skip: int = 0,
    limit: int = 100,
    dept_id: Optional[int] = None,
    year: Optional[int] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    query = db.query(models.Student)
    
    if dept_id:
        query = query.filter(models.Student.dept_id == dept_id)
    if year:
        query = query.filter(models.Student.year == year)
    if search:
        query = query.filter(
            (models.Student.name.ilike(f"%{search}%")) |
            (models.Student.reg_no.ilike(f"%{search}%"))
        )
    
    students = query.offset(skip).limit(limit).all()
    return students

@router.post("", response_model=schemas.StudentResponse)
async def create_student(
    student: schemas.StudentCreate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL
    ]))
):
    # Check if registration number exists
    db_student = db.query(models.Student).filter(models.Student.reg_no == student.reg_no).first()
    if db_student:
        raise HTTPException(status_code=400, detail="Registration number already exists")
    
    db_student = models.Student(**student.dict())
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    return db_student

@router.get("/{student_id}", response_model=schemas.StudentResponse)
async def get_student(
    student_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    student = db.query(models.Student).filter(models.Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student

@router.get("/{student_id}/profile", response_model=schemas.StudentProfile360)
async def get_student_profile_360(
    student_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    student = db.query(models.Student).filter(models.Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    marks = db.query(models.Mark).filter(models.Mark.student_id == student_id).all()
    attendance = db.query(models.Attendance).filter(models.Attendance.student_id == student_id).all()
    activities = db.query(models.ActivityParticipation).filter(
        models.ActivityParticipation.student_id == student_id
    ).all()
    latest_prediction = db.query(models.RiskPrediction).filter(
        models.RiskPrediction.student_id == student_id
    ).order_by(models.RiskPrediction.prediction_date.desc()).first()
    
    return {
        "student": student,
        "marks": marks,
        "attendance": attendance,
        "activities": activities,
        "latest_risk_prediction": latest_prediction
    }

@router.put("/{student_id}", response_model=schemas.StudentResponse)
async def update_student(
    student_id: int,
    student_update: schemas.StudentUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL
    ]))
):
    db_student = db.query(models.Student).filter(models.Student.student_id == student_id).first()
    if not db_student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    update_data = student_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_student, key, value)
    
    db.commit()
    db.refresh(db_student)
    return db_student

@router.delete("/{student_id}")
async def delete_student(
    student_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([models.RoleEnum.ADMIN]))
):
    db_student = db.query(models.Student).filter(models.Student.student_id == student_id).first()
    if not db_student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    db.delete(db_student)
    db.commit()
    return {"message": "Student deleted successfully"}
