from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models
import schemas
import auth

router = APIRouter(prefix="/api/students", tags=["Students"])

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

def get_all_student_models():
    return [
        models.StudentCSE, models.StudentECE, models.StudentEEE,
        models.StudentMECH, models.StudentCIVIL, models.StudentBIO,
        models.StudentAIDS
    ]

@router.get("", response_model=List[schemas.StudentResponse])
async def get_students(
    skip: int = 0,
    limit: int = 100,
    dept: Optional[str] = None, # Changed from dept_id
    year: Optional[int] = None,
    section: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    students = []
    
    # If dept is specified, query that table
    if dept:
        model = get_student_model(dept)
        if model:
            query = db.query(model)
            if year:
                query = query.filter(model.year == year)
            if section:
                query = query.filter(model.section == section)
            if search:
                query = query.filter(
                    (model.name.ilike(f"%{search}%")) |
                    (model.reg_no.ilike(f"%{search}%"))
                )
            students = query.offset(skip).limit(limit).all()
    else:
        # If no dept, query all tables (expensive, but needed if no filter)
        # For simplicity, let's just return empty or require dept for now
        # Or iterate all models
        for model in get_all_student_models():
            query = db.query(model)
            if year:
                query = query.filter(model.year == year)
            if section:
                query = query.filter(model.section == section)
            if search:
                query = query.filter(
                    (model.name.ilike(f"%{search}%")) |
                    (model.reg_no.ilike(f"%{search}%"))
                )
            students.extend(query.all())
        
        # Apply limit/skip manually
        students = students[skip: skip + limit]

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
    model = get_student_model(student.dept)
    if not model:
        raise HTTPException(status_code=400, detail="Invalid department")

    # Check if registration number exists in that dept
    db_student = db.query(model).filter(model.reg_no == student.reg_no).first()
    if db_student:
        raise HTTPException(status_code=400, detail="Registration number already exists")
    
    db_student = model(**student.dict())
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    return db_student

@router.get("/{reg_no}", response_model=schemas.StudentResponse)
async def get_student(
    reg_no: str,
    dept: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    if dept:
        model = get_student_model(dept)
        if model:
            student = db.query(model).filter(model.reg_no == reg_no).first()
            if student: return student
    else:
        # Search all tables
        for model in get_all_student_models():
            student = db.query(model).filter(model.reg_no == reg_no).first()
            if student: return student
            
    raise HTTPException(status_code=404, detail="Student not found")

@router.get("/{reg_no}/profile", response_model=schemas.StudentProfile360)
async def get_student_profile_360(
    reg_no: str,
    dept: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    student = None
    if dept:
        model = get_student_model(dept)
        if model:
            student = db.query(model).filter(model.reg_no == reg_no).first()
    else:
        for model in get_all_student_models():
            student = db.query(model).filter(model.reg_no == reg_no).first()
            if student: break
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    marks = db.query(models.Mark).filter(models.Mark.reg_no == reg_no).all()
    attendance = db.query(models.Attendance).filter(models.Attendance.reg_no == reg_no).all()
    activities = db.query(models.ActivityParticipation).filter(
        models.ActivityParticipation.reg_no == reg_no
    ).all()
    latest_prediction = db.query(models.RiskPrediction).filter(
        models.RiskPrediction.reg_no == reg_no
    ).order_by(models.RiskPrediction.prediction_date.desc()).first()
    
    return {
        "student": student,
        "marks": marks,
        "attendance": attendance,
        "activities": activities,
        "latest_risk_prediction": latest_prediction
    }

@router.put("/{reg_no}", response_model=schemas.StudentResponse)
async def update_student(
    reg_no: str,
    student_update: schemas.StudentUpdate,
    dept: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL
    ]))
):
    student = None
    if dept:
        model = get_student_model(dept)
        if model:
            student = db.query(model).filter(model.reg_no == reg_no).first()
    else:
        for model in get_all_student_models():
            student = db.query(model).filter(model.reg_no == reg_no).first()
            if student: break

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    update_data = student_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(student, key, value)
    
    db.commit()
    db.refresh(student)
    return student

@router.delete("/{reg_no}")
async def delete_student(
    reg_no: str,
    dept: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([models.RoleEnum.ADMIN]))
):
    student = None
    if dept:
        model = get_student_model(dept)
        if model:
            student = db.query(model).filter(model.reg_no == reg_no).first()
    else:
        for model in get_all_student_models():
            student = db.query(model).filter(model.reg_no == reg_no).first()
            if student: break

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    db.delete(student)
    db.commit()
    return {"message": "Student deleted successfully"}

@router.get("/me/dashboard-stats")
async def get_my_dashboard_stats(
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Get dashboard statistics for the currently logged-in student"""
    if current_user.role != models.RoleEnum.STUDENT or not current_user.reg_no:
        raise HTTPException(status_code=403, detail="Only students can access this endpoint")
    
    reg_no = current_user.reg_no
    
    # Get student info
    student = None
    if current_user.dept:
        model = get_student_model(current_user.dept)
        if model:
            student = db.query(model).filter(model.reg_no == reg_no).first()
    
    if not student:
        raise HTTPException(status_code=404, detail="Student record not found")
    
    # Calculate attendance percentage
    attendance_records = db.query(models.Attendance).filter(
        models.Attendance.reg_no == reg_no
    ).all()
    
    total_attendance = len(attendance_records)
    present_count = sum(1 for a in attendance_records if a.status in ['Present', 'P', 'OD'])
    attendance_percentage = round((present_count / total_attendance * 100), 1) if total_attendance > 0 else 0.0
    
    # Calculate GPA from marks
    marks = db.query(models.Mark).filter(models.Mark.reg_no == reg_no).all()
    
    # Grade to points mapping
    grade_points = {
        'O': 10, 'A+': 9, 'A': 8, 'B+': 7, 'B': 6,
        'C': 5, 'RA': 0, 'SA': 0, 'W': 0
    }
    
    total_points = 0
    total_subjects = 0
    for mark in marks:
        if mark.university_result_grade and mark.university_result_grade in grade_points:
            total_points += grade_points[mark.university_result_grade]
            total_subjects += 1
    
    gpa = round(total_points / total_subjects, 2) if total_subjects > 0 else 0.0
    
    # Count activities
    activities_count = db.query(models.ActivityParticipation).filter(
        models.ActivityParticipation.reg_no == reg_no
    ).count()
    
    # Get LIVE risk prediction (calculate based on current data)
    from ml_service import ml_service
    from datetime import datetime, timedelta
    try:
        # Check cache first: Is there a risk prediction from today?
        today = datetime.utcnow().date()
        recent_prediction = db.query(models.RiskPrediction).filter(
            models.RiskPrediction.reg_no == reg_no,
        ).order_by(models.RiskPrediction.prediction_date.desc()).first()

        if recent_prediction and recent_prediction.prediction_date.date() == today:
            print(f"DEBUG: Using cached risk prediction for {reg_no}")
            risk_level = recent_prediction.risk_level
            risk_score = recent_prediction.risk_score / 100.0  # It was stored as 0-100, we need it as 0-1 below
        else:
            print(f"DEBUG: Triggering live risk prediction for {reg_no}")
            live_prediction = ml_service.predict_risk(db, reg_no)
            print(f"DEBUG: Prediction result: {live_prediction}")
            risk_level = live_prediction['risk_level']
            risk_score = live_prediction['risk_score'] / 100.0
            
            # Save it so we don't calculate it again today
            ml_service.save_prediction(db, reg_no, live_prediction)
    except Exception as e:
        print(f"Error calculating risk: {e}")
        import traceback
        traceback.print_exc()
        risk_level = "LOW"
        risk_score = 0.0
    
    return {
        "student_info": {
            "name": student.name,
            "reg_no": student.reg_no,
            "dept": student.dept,
            "year": student.year,
            "section": student.section,
            "phone": student.phone,
            "address": student.address,
            "email": current_user.email
        },
        "attendance_percentage": attendance_percentage,
        "gpa": gpa,
        "activities_count": activities_count,
        "risk_level": risk_level,
        "risk_score": round(risk_score * 100, 1) if risk_score else 0.0
    }

@router.put("/me/profile")
async def update_my_profile(
    profile_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Update the currently logged-in student's profile"""
    if current_user.role != models.RoleEnum.STUDENT or not current_user.reg_no:
        raise HTTPException(status_code=403, detail="Only students can access this endpoint")
    
    reg_no = current_user.reg_no
    
    # Get student record
    student = None
    if current_user.dept:
        model = get_student_model(current_user.dept)
        if model:
            student = db.query(model).filter(model.reg_no == reg_no).first()
    
    if not student:
        raise HTTPException(status_code=404, detail="Student record not found")
    
    # Update allowed fields dynamically
    allowed_fields = [
        'phone', 'address', 'email', 'blood_group', 'religion', 'caste', 
        'abc_id', 'aadhar_no', 'father_name', 'father_occupation', 'father_phone',
        'mother_name', 'mother_occupation', 'mother_phone', 'guardian_name', 
        'guardian_occupation', 'guardian_phone', 'dob'
    ]
    
    for field in allowed_fields:
        if field in profile_data:
            setattr(student, field, profile_data[field])
    
    # Track if email changed to reissue token
    email_changed = False
    
    # Also update user table phone/email if provided
    if 'phone' in profile_data and profile_data['phone']:
        current_user.phone = profile_data['phone']
    if 'email' in profile_data and profile_data['email']:
        if current_user.email != profile_data['email']:
            email_changed = True
        current_user.email = profile_data['email']
    
    db.commit()
    db.refresh(student)
    
    response_data = {
        "message": "Profile updated successfully", 
        "student": student
    }
    
    # If the email changed, the frontend needs a new token because the token 
    # subject (`sub`) is the email address.
    if email_changed:
        from datetime import timedelta
        import config
        settings = config.get_settings()
        access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
        new_token = auth.create_access_token(
            data={"sub": current_user.email}, expires_delta=access_token_expires
        )
        response_data["access_token"] = new_token
        response_data["token_type"] = "bearer"
    
    return response_data

@router.get("/parent/dashboard-stats")
async def get_parent_dashboard_stats(
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Get dashboard statistics for parent's child (matched by child_phone)"""
    if current_user.role != models.RoleEnum.PARENT:
        raise HTTPException(status_code=403, detail="Only parents can access this endpoint")
    
    # Priority 1: Search by Register Number if available
    if current_user.child_reg_no:
        child_id = current_user.child_reg_no
        for model in get_all_student_models():
            student = db.query(model).filter(model.reg_no == child_id).first()
            if student: break
            
    # Priority 2: Search by Phone Number if Reg No not found or not provided
    if not student and current_user.child_phone:
        child_phone = current_user.child_phone
        for model in get_all_student_models():
            student = db.query(model).filter(model.phone == child_phone).first()
            if student: break
    
    if not student:
        return {
            "error": "Child not found",
            "message": f"No student found with Reg No: {current_user.child_reg_no or 'N/A'} or Phone: {current_user.child_phone or 'N/A'}",
            "parent_info": {
                "name": current_user.name,
                "child_name": current_user.child_name,
                "child_reg_no": current_user.child_reg_no,
                "child_phone": current_user.child_phone
            }
        }
    
    reg_no = student.reg_no
    
    # Calculate attendance percentage
    attendance_records = db.query(models.Attendance).filter(
        models.Attendance.reg_no == reg_no
    ).all()
    
    total_attendance = len(attendance_records)
    present_count = sum(1 for a in attendance_records if a.status in ['Present', 'P', 'OD'])
    attendance_percentage = round((present_count / total_attendance * 100), 1) if total_attendance > 0 else 0.0
    
    # Calculate GPA from marks
    marks = db.query(models.Mark).filter(models.Mark.reg_no == reg_no).all()
    
    grade_points = {
        'O': 10, 'A+': 9, 'A': 8, 'B+': 7, 'B': 6,
        'C': 5, 'RA': 0, 'SA': 0, 'W': 0
    }
    
    total_points = 0
    total_subjects = 0
    for mark in marks:
        if mark.university_result_grade and mark.university_result_grade in grade_points:
            total_points += grade_points[mark.university_result_grade]
            total_subjects += 1
    
    gpa = round(total_points / total_subjects, 2) if total_subjects > 0 else 0.0
    
    # Count activities
    activities_count = db.query(models.ActivityParticipation).filter(
        models.ActivityParticipation.reg_no == reg_no
    ).count()
    
    # Get latest risk prediction
    latest_prediction = db.query(models.RiskPrediction).filter(
        models.RiskPrediction.reg_no == reg_no
    ).order_by(models.RiskPrediction.prediction_date.desc()).first()
    
    risk_level = latest_prediction.risk_level if latest_prediction else "LOW"
    risk_score = latest_prediction.risk_score if latest_prediction else 0.0
    
    return {
        "parent_info": {
            "name": current_user.name,
            "occupation": current_user.occupation
        },
        "child_info": {
            "name": student.name,
            "reg_no": student.reg_no,
            "dept": student.dept,
            "year": student.year,
            "section": student.section,
            "semester": student.semester,
            "phone": student.phone
        },
        "attendance_percentage": attendance_percentage,
        "gpa": gpa,
        "activities_count": activities_count,
        "risk_level": risk_level,
        "risk_score": round(risk_score * 100, 1) if risk_score else 0.0
    }

