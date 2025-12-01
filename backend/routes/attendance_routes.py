from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models
import schemas
import auth

router = APIRouter(prefix="/api/attendance", tags=["Attendance"])

@router.post("", response_model=schemas.AttendanceResponse)
async def create_attendance(
    attendance: schemas.AttendanceCreate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL
    ]))
):
    # Calculate attendance percentage
    percentage = (attendance.attended_classes / attendance.total_classes) * 100 if attendance.total_classes > 0 else 0
    
    db_attendance = models.Attendance(
        **attendance.dict(),
        attendance_percentage=percentage
    )
    db.add(db_attendance)
    db.commit()
    db.refresh(db_attendance)
    return db_attendance

@router.get("/student/{student_id}", response_model=List[schemas.AttendanceResponse])
async def get_student_attendance(
    student_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    attendance = db.query(models.Attendance).filter(
        models.Attendance.student_id == student_id
    ).all()
    return attendance

@router.get("/{attendance_id}", response_model=schemas.AttendanceResponse)
async def get_attendance(
    attendance_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    attendance = db.query(models.Attendance).filter(
        models.Attendance.attendance_id == attendance_id
    ).first()
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    return attendance

@router.delete("/{attendance_id}")
async def delete_attendance(
    attendance_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL
    ]))
):
    db_attendance = db.query(models.Attendance).filter(
        models.Attendance.attendance_id == attendance_id
    ).first()
    if not db_attendance:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    
    db.delete(db_attendance)
    db.commit()
    return {"message": "Attendance record deleted successfully"}
