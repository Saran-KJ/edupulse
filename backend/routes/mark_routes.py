from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models
import schemas
import auth

router = APIRouter(prefix="/api/marks", tags=["Marks"])

@router.post("/bulk", response_model=List[schemas.MarkResponse])
async def create_bulk_marks(
    bulk_data: schemas.BulkMarkEntry,
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
    """Create or update marks in bulk"""
    created_marks = []
    
    for mark_data in bulk_data.marks:
        # Validate subject_code against subjects table and auto-fill title
        subject = db.query(models.Subject).filter(
            models.Subject.subject_code == mark_data.subject_code
        ).first()
        if subject and (not mark_data.subject_title or mark_data.subject_title.strip() == ""):
            mark_data.subject_title = subject.subject_title
        elif not subject:
            print(f"Warning: subject_code '{mark_data.subject_code}' not found in subjects table")

        # Check if mark already exists
        existing_mark = db.query(models.Mark).filter(
            models.Mark.reg_no == mark_data.reg_no,
            models.Mark.subject_code == mark_data.subject_code,
            models.Mark.semester == mark_data.semester
        ).first()
        
        if existing_mark:
            # Update existing mark
            for key, value in mark_data.dict().items():
                setattr(existing_mark, key, value)
            created_marks.append(existing_mark)
        else:
            # Create new mark
            db_mark = models.Mark(**mark_data.dict())
            db.add(db_mark)
            created_marks.append(db_mark)
    
    db.commit()
    for mark in created_marks:
        db.refresh(mark)
        
    # Trigger risk prediction for all affected students
    # Use a set to avoid duplicate predictions for the same student
    affected_students = set(mark.reg_no for mark in created_marks)
    
    from ml_service import ml_service
    
    for reg_no in affected_students:
        try:
            print(f"Triggering risk update for {reg_no} after bulk upload")
            prediction = ml_service.predict_risk(db, reg_no)
            ml_service.save_prediction(db, reg_no, prediction)
        except Exception as e:
            print(f"Error updating risk for {reg_no}: {e}")
    
    # Trigger personalized learning plan generation
    from routes.learning_routes import generate_plan_for_subject
    affected_pairs = set((mark.reg_no, mark.subject_code) for mark in created_marks)
    for reg_no, subject_code in affected_pairs:
        try:
            print(f"Generating learning plan for {reg_no}/{subject_code}")
            generate_plan_for_subject(db, reg_no, subject_code)
        except Exception as e:
            print(f"Error generating plan for {reg_no}/{subject_code}: {e}")
            
    return created_marks

@router.get("/class/{dept}/{year}/{section}", response_model=List[schemas.MarkResponse])
async def get_class_marks(
    dept: str,
    year: int,
    section: str,
    semester: Optional[int] = None,
    subject_code: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Get all marks for students in a specific class"""
    query = db.query(models.Mark).filter(
        models.Mark.dept == dept,
        models.Mark.year == year,
        models.Mark.section == section
    )
    
    if semester:
        query = query.filter(models.Mark.semester == semester)
        
    if subject_code:
        query = query.filter(models.Mark.subject_code == subject_code)
    
    marks = query.all()
    return marks

@router.get("/{mark_id}", response_model=schemas.MarkResponse)
async def get_mark(
    mark_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Get a specific mark by ID"""
    mark = db.query(models.Mark).filter(models.Mark.id == mark_id).first()
    if not mark:
        raise HTTPException(status_code=404, detail="Mark not found")
    return mark

@router.put("/{mark_id}", response_model=schemas.MarkResponse)
async def update_mark(
    mark_id: int,
    mark_update: schemas.MarkUpdate,
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
    """Update a specific mark"""
    db_mark = db.query(models.Mark).filter(models.Mark.id == mark_id).first()
    if not db_mark:
        raise HTTPException(status_code=404, detail="Mark not found")
    
    # Update only provided fields
    update_data = mark_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_mark, key, value)
    
    db.commit()
    db.refresh(db_mark)
    
    # Trigger risk prediction
    from ml_service import ml_service
    try:
        print(f"Triggering risk update for {db_mark.reg_no} after mark update")
        prediction = ml_service.predict_risk(db, db_mark.reg_no)
        ml_service.save_prediction(db, db_mark.reg_no, prediction)
    except Exception as e:
        print(f"Error updating risk for {db_mark.reg_no}: {e}")
    
    # Trigger personalized learning plan
    from routes.learning_routes import generate_plan_for_subject
    try:
        generate_plan_for_subject(db, db_mark.reg_no, db_mark.subject_code)
    except Exception as e:
        print(f"Error generating plan for {db_mark.reg_no}/{db_mark.subject_code}: {e}")
        
    return db_mark

@router.delete("/{mark_id}")
async def delete_mark(
    mark_id: int,
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
    """Delete a specific mark"""
    db_mark = db.query(models.Mark).filter(models.Mark.id == mark_id).first()
    if not db_mark:
        raise HTTPException(status_code=404, detail="Mark not found")
    
    reg_no = db_mark.reg_no
    db.delete(db_mark)
    db.commit()
    
    # Trigger risk prediction
    from ml_service import ml_service
    try:
        print(f"Triggering risk update for {reg_no} after mark deletion")
        prediction = ml_service.predict_risk(db, reg_no)
        ml_service.save_prediction(db, reg_no, prediction)
    except Exception as e:
        print(f"Error updating risk for {reg_no}: {e}")
        
    return {"message": "Mark deleted successfully"}

@router.get("/student/{reg_no}", response_model=List[schemas.MarkResponse])
async def get_student_marks(
    reg_no: str,
    semester: Optional[int] = None,
    exclude_labs: Optional[bool] = False,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Get all marks for a specific student"""
    query = db.query(models.Mark).filter(models.Mark.reg_no == reg_no)
    
    if semester:
        query = query.filter(models.Mark.semester == semester)
        
    if exclude_labs:
        query = query.join(
            models.Subject,
            models.Mark.subject_code == models.Subject.subject_code
        ).filter(
            models.Subject.category != 'LAB'
        )
    
    marks = query.all()
    return marks


# Anna University grade-point scale
GRADE_POINTS = {'O': 10, 'A+': 9, 'A': 8, 'B+': 7, 'B': 6, 'C': 5, 'U': 0, 'AREAR': 0, 'F': 0}
SEMESTER_ROMAN = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V', 6: 'VI', 7: 'VII', 8: 'VIII'}


@router.get("/cgpa/{reg_no}")
async def get_cgpa(
    reg_no: str,
    db: Session = Depends(get_db),
    current_user=Depends(auth.get_current_active_user)
):
    """
    Compute semester-wise GPA and overall CGPA for a student.
    Uses credits from the subjects table and grades from the marks table.
    Formula: GPA = Σ(grade_points × credits) / Σ(credits)
    """
    marks = db.query(models.Mark).filter(models.Mark.reg_no == reg_no).all()

    if not marks:
        return {
            "reg_no": reg_no,
            "overall_cgpa": 0.0,
            "total_credits_earned": 0,
            "semesters": [],
            "grade_distribution": {}
        }

    # Group marks by semester
    semester_data = {}
    grade_distribution = {}

    for mark in marks:
        sem = mark.semester
        grade = (mark.university_result_grade or "").strip().upper()
        if not grade:
            continue  # Skip if no university result yet

        grade_pt = GRADE_POINTS.get(grade, None)
        if grade_pt is None:
            continue  # Unknown grade — skip

        # Look up credit from subjects table using Roman numeral
        roman_sem = SEMESTER_ROMAN.get(sem, str(sem))
        subject = db.query(models.Subject).filter(
            models.Subject.subject_code == mark.subject_code
        ).first()
        credit = float(subject.credits) if subject and subject.credits else 3.0  # default fallback

        if sem not in semester_data:
            semester_data[sem] = {
                "semester": sem,
                "semester_label": f"Semester {roman_sem}",
                "subjects": [],
                "total_credits": 0,
                "weighted_points": 0.0,
                "gpa": 0.0,
                "arrears": 0
            }

        semester_data[sem]["subjects"].append({
            "subject_code": mark.subject_code,
            "subject_title": mark.subject_title,
            "grade": grade,
            "grade_points": grade_pt,
            "credits": credit,
            "credit_points": round(grade_pt * credit, 2),
            "status": "Pass" if grade_pt > 0 else "Fail"
        })
        semester_data[sem]["weighted_points"] += grade_pt * credit
        semester_data[sem]["total_credits"] += credit
        if grade_pt == 0:
            semester_data[sem]["arrears"] += 1

        # Grade distribution count
        grade_distribution[grade] = grade_distribution.get(grade, 0) + 1

    # Compute per-semester GPA
    semesters_list = []
    total_weighted = 0.0
    total_credits_all = 0.0

    for sem in sorted(semester_data.keys()):
        sd = semester_data[sem]
        if sd["total_credits"] > 0:
            sd["gpa"] = round(sd["weighted_points"] / sd["total_credits"], 2)
        total_weighted += sd["weighted_points"]
        total_credits_all += sd["total_credits"]
        semesters_list.append(sd)

    overall_cgpa = round(total_weighted / total_credits_all, 2) if total_credits_all > 0 else 0.0

    return {
        "reg_no": reg_no,
        "overall_cgpa": overall_cgpa,
        "total_credits_earned": round(total_credits_all, 1),
        "semesters": semesters_list,
        "grade_distribution": grade_distribution
    }

