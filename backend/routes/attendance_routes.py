from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import date
from database import get_db
import models
import schemas
import auth
from fastapi import BackgroundTasks
from sms_service import sms_service

router = APIRouter(prefix="/api/attendance", tags=["Attendance"])

@router.post("/bulk", response_model=List[schemas.AttendanceResponse])
async def create_bulk_attendance(
    bulk_data: schemas.BulkAttendanceCreate,
    background_tasks: BackgroundTasks,
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
        # Check if record already exists for this student and date and period
        existing = db.query(models.Attendance).filter(
            models.Attendance.reg_no == item.reg_no,
            models.Attendance.date == bulk_data.date,
            models.Attendance.period == bulk_data.period
        ).first()
        
        if existing:
            # Update status
            existing.status = item.status
            existing.reason = item.reason
            existing.subject_code = bulk_data.subject_code
            existing.time = bulk_data.time
            existing.semester = bulk_data.semester # Update semester
            created_records.append(existing)
        else:
            # Create new record
            new_record = models.Attendance(
                reg_no=item.reg_no,
                student_name=item.student_name,
                date=bulk_data.date,
                period=bulk_data.period,
                time=bulk_data.time,
                subject_code=bulk_data.subject_code,
                status=item.status,
                year=bulk_data.year,
                semester=bulk_data.semester,
                section=bulk_data.section,
                dept=bulk_data.dept,
                reason=item.reason
            )
            db.add(new_record)
            created_records.append(new_record)
            
    db.commit()
    for r in created_records:
        db.refresh(r)
    
    # Trigger low attendance alerts in the background
    affected_students = list(set(item.reg_no for item in bulk_data.attendance_list))
    
    def check_and_notify_attendance(reg_nos: List[str], semester: int, dept: str, db_session: Session):
        for reg_no in reg_nos:
            try:
                # Calculate cumulative attendance for this semester
                total = db_session.query(models.Attendance).filter(
                    models.Attendance.reg_no == reg_no,
                    models.Attendance.semester == semester
                ).count()
                
                if total == 0: continue
                
                present = db_session.query(models.Attendance).filter(
                    models.Attendance.reg_no == reg_no,
                    models.Attendance.semester == semester,
                    models.Attendance.status == "Present"
                ).count()
                
                percentage = (present / total) * 100
                
                if percentage < 75:
                    phone, name = sms_service.get_parent_phone(db_session, reg_no, dept)
                    if phone:
                        sms_service.notify_low_attendance(phone, name, percentage)
            except Exception as e:
                print(f"Error checking attendance alert for {reg_no}: {e}")

    background_tasks.add_task(check_and_notify_attendance, affected_students, bulk_data.semester, bulk_data.dept, db)
    
    return created_records

@router.get("/class/{dept}/{year}/{section}/{date_str}", response_model=List[schemas.AttendanceResponse])
async def get_class_attendance(
    dept: str,
    year: int,
    section: str,
    date_str: str,
    period: int = 1,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Get attendance for a specific class and date and period"""
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
        models.Attendance.date == query_date,
        models.Attendance.period == period
    )
    
    # Also filter by time if period is not enough or if we want exact records
    # for simplicity, we focus on period first but time is returned
    
    return query.all()

@router.get("/student/{reg_no}", response_model=List[schemas.AttendanceResponse])
async def get_student_attendance(
    reg_no: str,
    semester: int = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Get attendance history for a student, optionally filtered by semester"""
    query = db.query(models.Attendance).filter(
        models.Attendance.reg_no == reg_no
    )
    
    if semester:
        query = query.filter(models.Attendance.semester == semester)
        
    attendance = query.order_by(models.Attendance.date.desc()).all()
    return attendance
