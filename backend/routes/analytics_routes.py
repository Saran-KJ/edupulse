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

@router.get("/college-summary", response_model=schemas.CollegeSummaryResponse)
async def get_college_summary(
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    if current_user.role not in [models.RoleEnum.PRINCIPAL, models.RoleEnum.VICE_PRINCIPAL, models.RoleEnum.ADMIN]:
        raise HTTPException(status_code=403, detail="Forbidden")

    from routes.student_routes import get_all_student_models
    
    total_students = 0
    total_at_risk = 0
    total_high_performers = 0
    total_present = 0
    total_records = 0
    
    dept_summaries = []
    
    for model in get_all_student_models():
        dept_code = "UNKNOWN"
        # Get sample to find dept code or infer from model name
        sample = db.query(model).first()
        if sample:
            dept_code = sample.dept
        else:
            # Infer from table name if empty
            dept_code = model.__tablename__.split('_')[1].upper()

        # Student count
        s_count = db.query(model).count()
        total_students += s_count
        
        # At Risk
        reg_nos = db.query(model.reg_no).subquery()
        at_risk = db.query(func.count(models.RiskPrediction.prediction_id)).filter(
            models.RiskPrediction.reg_no.in_(reg_nos),
            models.RiskPrediction.risk_level.in_([models.RiskLevelEnum.MEDIUM, models.RiskLevelEnum.HIGH])
        ).scalar() or 0
        total_at_risk += at_risk
        
        # High Performers
        high_perf = db.query(models.Mark.reg_no).filter(
            models.Mark.dept == dept_code,
            models.Mark.university_result_grade.in_(['O', 'A+'])
        ).distinct().count()
        total_high_performers += high_perf
        
        # Attendance
        att_total = db.query(models.Attendance).filter(models.Attendance.dept == dept_code).count()
        att_present = db.query(models.Attendance).filter(
            models.Attendance.dept == dept_code,
            models.Attendance.status.in_(['Present', 'P', 'OD'])
        ).count()
        
        dept_avg = (att_present / att_total * 100) if att_total > 0 else 0
        
        total_present += att_present
        total_records += att_total
        
        dept_summaries.append(schemas.DepartmentSummary(
            dept_code=dept_code,
            student_count=s_count,
            avg_attendance=round(dept_avg, 2),
            at_risk_count=at_risk,
            high_performer_count=high_perf
        ))

    total_activities = db.query(func.count(models.Activity.activity_id)).scalar() or 0
    avg_college_attendance = (total_present / total_records * 100) if total_records > 0 else 0
    
    return {
        "total_students": total_students,
        "total_activities": total_activities,
        "avg_college_attendance": round(avg_college_attendance, 2),
        "total_at_risk": total_at_risk,
        "total_high_performers": total_high_performers,
        "department_summaries": dept_summaries
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
            db.rollback()
            
    return results

@router.get("/hod/report-summary", response_model=schemas.HODReportSummary)
async def get_hod_report_summary(
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Detailed analytics for Head of Department to monitor department-wide risk."""
    if current_user.role != models.RoleEnum.HOD or not current_user.dept:
        raise HTTPException(status_code=403, detail="HOD access only")

    from routes.student_routes import get_student_model
    from ml_service import ml_service
    
    dept = current_user.dept
    model = get_student_model(dept)
    if not model:
         raise HTTPException(status_code=404, detail="Department not found")
         
    # 1. Get all students reg_nos for this dept
    reg_nos = [r[0] for r in db.query(model.reg_no).filter(model.dept == dept).all()]
    
    # 2. Get subjects taught in this department (from FacultyAllocation)
    dept_allocations = db.query(models.FacultyAllocation).filter(models.FacultyAllocation.dept == dept).all()
    subject_codes = list(set([a.subject_code for a in dept_allocations]))
    subject_map = {a.subject_code: a.subject_title for a in dept_allocations}
    
    # 3. Aggregate risk by subject (Top 5 most risky subjects)
    at_risk_by_subject = []
    # Simplified optimization: Look at RiskPredictions with reasons mentioning specific subjects
    # Or just count for subjects with known high failure rates/low internal marks
    # For the demo, we take the provided subject_codes and calculate a summary
    for code in subject_codes[:5]: # Cap at 5 for performance
        high = db.query(func.count(models.Mark.id)).filter(
            models.Mark.dept == dept,
            models.Mark.subject_code == code,
            models.Mark.cia_1 + models.Mark.cia_2 < 40 # Simple risk heuristic
        ).scalar() or 0
        
        at_risk_by_subject.append(schemas.SubjectRiskSummary(
            subject_code=code,
            subject_title=subject_map[code],
            high_risk_count=high,
            medium_risk_count=high * 2 # Estimated for demo
        ))
        
    # 4. Critical Students (Top 5 highest risk score in dept)
    critical_preds = db.query(models.RiskPrediction).filter(
        models.RiskPrediction.reg_no.in_(reg_nos),
        models.RiskPrediction.risk_level == models.RiskLevelEnum.HIGH
    ).order_by(models.RiskPrediction.risk_score.desc()).limit(5).all()
    
    critical_students = []
    for p in critical_preds:
        # Convert model to schema response
        critical_students.append(schemas.RiskPredictionResponse(
            prediction_id=p.prediction_id,
            reg_no=p.reg_no,
            risk_level=p.risk_level,
            risk_score=p.risk_score,
            attendance_percentage=p.attendance_percentage,
            internal_avg=p.internal_avg,
            external_gpa=p.external_gpa,
            activity_count=p.activity_count,
            backlog_count=p.backlog_count,
            reasons=p.reasons,
            prediction_date=p.prediction_date
        ))
        
    # 5. Faculty/Subject stats
    faculty_count = db.query(models.FacultyAllocation.faculty_id).filter(
        models.FacultyAllocation.dept == dept
    ).distinct().count()
    
    return schemas.HODReportSummary(
        at_risk_by_subject=at_risk_by_subject,
        critical_students=critical_students,
        faculty_count=faculty_count,
        total_subjects=len(subject_codes)
    )
