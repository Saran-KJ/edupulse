from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import date
from database import get_db
import models
import schemas
import auth

router = APIRouter(prefix="/api/attendance", tags=["Attendance"])

@router.post("/bulk", response_model=List[schemas.AttendanceResponse])
async def create_bulk_attendance(
    bulk_data: schemas.BulkAttendanceCreate,
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
    """Create or update daily attendance in bulk"""
    created_records = []
    
    for item in bulk_data.attendance_list:
        # Check if record already exists for this student and date
        existing = db.query(models.Attendance).filter(
            models.Attendance.reg_no == item.reg_no,
            models.Attendance.date == bulk_data.date
        ).first()
        
        if existing:
            # Update status
            existing.status = item.status
            existing.reason = item.reason
            created_records.append(existing)
        else:
            # Create new record
            new_record = models.Attendance(
                reg_no=item.reg_no,
                student_name=item.student_name,
                date=bulk_data.date,
                status=item.status,
                year=bulk_data.year,
                section=bulk_data.section,
                dept=bulk_data.dept,
                reason=item.reason
            )
            db.add(new_record)
            created_records.append(new_record)
            
    db.commit()
    for r in created_records:
        db.refresh(r)
    return created_records

@router.get("/class/{dept}/{year}/{section}/{date_str}", response_model=List[schemas.AttendanceResponse])
async def get_class_attendance(
    dept: str,
    year: int,
    section: str,
    date_str: str,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Get attendance for a specific class and date"""
    # Parse date string to date object
    try:
        query_date = date.fromisoformat(date_str)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")

    # Filter by class details directly
    query = db.query(models.Attendance).filter(
        models.Attendance.dept == dept,
        models.Attendance.year == year,
        models.Attendance.section == section,
        models.Attendance.date == query_date
    )
    
    return query.all()

@router.get("/student/{reg_no}", response_model=List[schemas.AttendanceResponse])
async def get_student_attendance(
    reg_no: str,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Get attendance history for a student"""
    attendance = db.query(models.Attendance).filter(
        models.Attendance.reg_no == reg_no
    ).order_by(models.Attendance.date.desc()).all()
    return attendance
