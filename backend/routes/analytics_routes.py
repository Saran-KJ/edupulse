from typing import List
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
    from routes.student_routes import get_student_model, get_all_student_models

    # Base queries - need to be dynamic
    attendance_query = db.query(models.Attendance)
    mark_query = db.query(models.Mark)
    
    total_students = 0
    at_risk_count = 0
    
    # Filter if Class Advisor
    if current_user.role == models.RoleEnum.CLASS_ADVISOR and current_user.dept and current_user.year and current_user.section:
        print(f"DEBUG: Filtering for Class Advisor: {current_user.dept}, {current_user.year}, {current_user.section}")
        
        model = get_student_model(current_user.dept)
        if model:
            student_query = db.query(model).filter(
                model.dept == current_user.dept,
                model.year == int(current_user.year),
                model.section == current_user.section
            )
            total_students = student_query.count()
            print(f"DEBUG: Student count: {total_students}")
            
            # Filter marks by students in this class
            sub_query = db.query(model.reg_no).filter(
                model.dept == current_user.dept,
                model.year == int(current_user.year),
                model.section == current_user.section
            )
            mark_query = mark_query.filter(models.Mark.reg_no.in_(sub_query))
            
            # Filter At Risk
            at_risk_query = db.query(func.count(models.RiskPrediction.prediction_id)).filter(
                models.RiskPrediction.risk_level.in_([models.RiskLevelEnum.MEDIUM, models.RiskLevelEnum.HIGH]),
                models.RiskPrediction.reg_no.in_(sub_query)
            )
            at_risk_count = at_risk_query.scalar() or 0
        
        attendance_query = attendance_query.filter(
            models.Attendance.dept == current_user.dept,
            models.Attendance.year == int(current_user.year),
            models.Attendance.section == current_user.section
        )
        print(f"DEBUG: Attendance count: {attendance_query.count()}")
        
    elif current_user.role == models.RoleEnum.HOD and current_user.dept:
        print(f"DEBUG: Filtering for HOD: {current_user.dept}")
        
        # Get all student models for this department (usually just one, but helper returns list or model)
        model = get_student_model(current_user.dept)
        if model:
            student_query = db.query(model).filter(model.dept == current_user.dept)
            total_students = student_query.count()
            
            # Filter marks
            sub_query = db.query(model.reg_no).filter(model.dept == current_user.dept)
            mark_query = mark_query.filter(models.Mark.reg_no.in_(sub_query))
            
            # Filter At Risk
            at_risk_query = db.query(func.count(models.RiskPrediction.prediction_id)).filter(
                models.RiskPrediction.risk_level.in_([models.RiskLevelEnum.MEDIUM, models.RiskLevelEnum.HIGH]),
                models.RiskPrediction.reg_no.in_(sub_query)
            )
            at_risk_count = at_risk_query.scalar() or 0
            
        attendance_query = attendance_query.filter(models.Attendance.dept == current_user.dept)
    else:
        print(f"DEBUG: No Class Advisor filtering. Role: {current_user.role}, Dept: {current_user.dept}")
        # Global stats - sum of all tables
        for model in get_all_student_models():
            total_students += db.query(model).count()
            
        # Global risk
        at_risk_count = db.query(func.count(models.RiskPrediction.prediction_id)).filter(
            models.RiskPrediction.risk_level.in_([models.RiskLevelEnum.MEDIUM, models.RiskLevelEnum.HIGH])
        ).scalar() or 0

    
    # Total activities (Global for now)
    total_activities = db.query(func.count(models.Activity.activity_id)).scalar()
    
    # Average attendance calculation
    total_att_records = attendance_query.count()
    present_att_records = attendance_query.filter(models.Attendance.status.in_(['Present', 'P', 'OD'])).count()
    avg_attendance = (present_att_records / total_att_records * 100) if total_att_records > 0 else 0
    
    # High performers
    high_performers = mark_query.filter(
        models.Mark.university_result_grade.in_(['O', 'A+'])
    ).distinct(models.Mark.reg_no).count()
    
    return {
        "total_students": total_students,
        "total_activities": total_activities,
        "avg_attendance": round(avg_attendance, 2),
        "at_risk_count": at_risk_count,
        "high_performers": high_performers
    }

@router.get("/department/{dept}")
async def get_department_analytics(
    dept: str,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    from routes.student_routes import get_student_model
    model = get_student_model(dept)
    if not model:
        raise HTTPException(status_code=400, detail="Invalid department")

    # Department students count
    student_count = db.query(func.count(model.student_id)).filter(
        model.dept == dept
    ).scalar()
    
    # Average marks by semester - Placeholder as structure changed
    marks_by_semester = []
    
    # Attendance by year
    attendance_by_year = db.query(
        models.Attendance.year,
        func.avg(models.Attendance.attendance_percentage).label('avg_attendance') # This column might not exist in Attendance table, check models
    ).filter(
        models.Attendance.dept == dept
    ).group_by(models.Attendance.year).all()
    
    # Note: Attendance table doesn't have attendance_percentage column in models.py currently shown.
    # It was in init_db but models.py shows status.
    # Assuming we calculate from status.
    
    return {
        "student_count": student_count,
        "marks_by_semester": marks_by_semester,
        "attendance_by_year": [] # Placeholder until attendance logic is fixed
    }


@router.get("/credits-summary")
async def get_credits_summary(
    semester: str = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """
    Get credit distribution summary from the subjects table.
    Returns per-semester totals and per-category breakdown.
    """
    query = db.query(models.Subject)
    if semester:
        query = query.filter(models.Subject.semester == semester)

    subjects = query.all()

    # Per-semester credit totals
    semester_credits = {}
    category_credits = {}

    for s in subjects:
        sem = s.semester or "Unknown"
        cat = s.category or "Unknown"
        cred = float(s.credits or 0)

        semester_credits[sem] = semester_credits.get(sem, 0) + cred
        category_credits[cat] = category_credits.get(cat, 0) + cred

    return {
        "total_subjects": len(subjects),
        "total_credits": sum(semester_credits.values()),
        "semester_credits": semester_credits,
        "category_credits": category_credits,
    }

@router.get("/student/{reg_no}/subject-risks", response_model=List[schemas.SubjectRiskResponse])
async def get_student_subject_risks(
    reg_no: str,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """
    Get consolidated risk analysis for all subjects a student is enrolled in or has attempted.
    Combines data from the Marks table and StudentQuizAttempt table.
    """
    from ml_service import ml_service
    
    # 1. Get subjects from Marks table
    marks = db.query(models.Mark).filter(models.Mark.reg_no == reg_no).all()
    subject_map = {} # subject_code -> {title, semester, has_marks}
    
    for m in marks:
        # Skip labs if strictly academic risk is focused, but here we include all for completeness
        # SubjectRiskScreen on mobile can filter further if needed
        subject_map[m.subject_code] = {
            "title": m.subject_title,
            "semester": m.semester,
            "has_marks": True
        }
    
    # 2. Get subjects from QuizAttempts table (for early risk detection before marks are out)
    quiz_attempts = db.query(models.StudentQuizAttempt).filter(
        models.StudentQuizAttempt.reg_no == reg_no
    ).all()
    
    for q in quiz_attempts:
        if q.subject not in subject_map:
            # Try to get subject title from subjects table or use subject_code as title
            subj_info = db.query(models.Subject).filter(
                models.Subject.subject_code == q.subject
            ).first()
            
            subject_map[q.subject] = {
                "title": subj_info.subject_title if subj_info else q.subject,
                "semester": int(subj_info.semester) if (subj_info and subj_info.semester and subj_info.semester.isdigit()) else None,
                "has_marks": False
            }
            
    # 3. Calculate risk for each identified subject
    results = []
    for code, info in subject_map.items():
        try:
            risk = ml_service.calculate_subject_risk(db, reg_no, code)
            results.append({
                "subject_code": code,
                "subject_title": info["title"],
                "risk_level": risk["risk_level"],
                "score": risk["score"],
                "basis": risk["basis"],
                "has_marks": info["has_marks"],
                "semester": info["semester"]
            })
        except Exception as e:
            print(f"Error calculating subject risk for {code}: {e}")
            
    return results
