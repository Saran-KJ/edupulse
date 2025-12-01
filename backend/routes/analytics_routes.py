from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import get_db
import models
import schemas
import auth

router = APIRouter(prefix="/api/analytics", tags=["Analytics"])

@router.get("/dashboard", response_model=schemas.DashboardStats)
async def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    # Total students
    total_students = db.query(func.count(models.Student.student_id)).scalar()
    
    # Total activities
    total_activities = db.query(func.count(models.Activity.activity_id)).scalar()
    
    # Average attendance
    avg_attendance = db.query(func.avg(models.Attendance.attendance_percentage)).scalar() or 0
    
    # At-risk students count
    at_risk_count = db.query(func.count(models.RiskPrediction.prediction_id)).filter(
        models.RiskPrediction.risk_level.in_([models.RiskLevelEnum.MEDIUM, models.RiskLevelEnum.HIGH])
    ).filter(
        models.RiskPrediction.prediction_id.in_(
            db.query(func.max(models.RiskPrediction.prediction_id)).group_by(
                models.RiskPrediction.student_id
            )
        )
    ).scalar() or 0
    
    # High performers (students with avg marks > 80)
    high_performers = db.query(func.count(func.distinct(models.Mark.student_id))).filter(
        models.Mark.student_id.in_(
            db.query(models.Mark.student_id).group_by(models.Mark.student_id).having(
                func.avg(models.Mark.total_marks) > 80
            )
        )
    ).scalar() or 0
    
    return {
        "total_students": total_students,
        "total_activities": total_activities,
        "avg_attendance": round(avg_attendance, 2),
        "at_risk_count": at_risk_count,
        "high_performers": high_performers
    }

@router.get("/department/{dept_id}")
async def get_department_analytics(
    dept_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    # Department students count
    student_count = db.query(func.count(models.Student.student_id)).filter(
        models.Student.dept_id == dept_id
    ).scalar()
    
    # Average marks by semester
    marks_by_semester = db.query(
        models.Mark.semester,
        func.avg(models.Mark.total_marks).label('avg_marks')
    ).join(models.Student).filter(
        models.Student.dept_id == dept_id
    ).group_by(models.Mark.semester).all()
    
    # Attendance by year
    attendance_by_year = db.query(
        models.Student.year,
        func.avg(models.Attendance.attendance_percentage).label('avg_attendance')
    ).join(models.Attendance).filter(
        models.Student.dept_id == dept_id
    ).group_by(models.Student.year).all()
    
    return {
        "student_count": student_count,
        "marks_by_semester": [{"semester": sem, "avg_marks": round(avg, 2)} for sem, avg in marks_by_semester],
        "attendance_by_year": [{"year": year, "avg_attendance": round(avg, 2)} for year, avg in attendance_by_year]
    }
