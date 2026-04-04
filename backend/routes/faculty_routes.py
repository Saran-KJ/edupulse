from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, distinct
from typing import List
from database import get_db
import models
import schemas
from auth import get_current_active_user

router = APIRouter(
    prefix="/api/faculty",
    tags=["faculty"]
)

def get_student_model(dept: str):
    """Get the appropriate student model based on department"""
    dept_upper = dept.upper()
    model_map = {
        'CSE': models.StudentCSE,
        'ECE': models.StudentECE,
        'EEE': models.StudentEEE,
        'MECH': models.StudentMECH,
        'CIVIL': models.StudentCIVIL,
        'BIO': models.StudentBIO,
        'AIDS': models.StudentAIDS,
    }
    return model_map.get(dept_upper)

@router.get("/my-classes", response_model=List[schemas.FacultyClassInfo])
async def get_faculty_classes(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get all unique classes taught by the current faculty member.
    Returns list of classes with dept, year, section, subject_code, and subject_title.
    """
    if current_user.role != models.RoleEnum.FACULTY:
        raise HTTPException(status_code=403, detail="Only faculty can access this endpoint")
    
    # Query FacultyAllocation for entries where faculty_id matches current user's id
    # FacultyAllocation has the same fields we need: dept, year, section, subject_code, subject_title
    allocations = db.query(
        models.FacultyAllocation.dept,
        models.FacultyAllocation.year,
        models.FacultyAllocation.section,
        models.FacultyAllocation.subject_code,
        models.FacultyAllocation.subject_title
    ).filter(
        models.FacultyAllocation.faculty_id == current_user.user_id
    ).distinct().all()
    
    # Convert to FacultyClassInfo objects
    classes = [
        schemas.FacultyClassInfo(
            dept=entry.dept,
            year=entry.year,
            section=entry.section,
            subject_code=entry.subject_code,
            subject_title=entry.subject_title
        )
        for entry in allocations
    ]
    
    return classes

@router.get("/dashboard-stats", response_model=schemas.FacultyDashboardStats)
async def get_faculty_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get dashboard statistics for the faculty member.
    Returns total classes, total students across all classes, and subjects taught.
    """
    if current_user.role != models.RoleEnum.FACULTY:
        raise HTTPException(status_code=403, detail="Only faculty can access this endpoint")
    
    # Get all allocations for this faculty
    allocations = db.query(models.FacultyAllocation).filter(
        models.FacultyAllocation.faculty_id == current_user.user_id
    ).all()
    
    total_classes = len(allocations)
    
    # Get unique subjects
    subjects = len(set(a.subject_code for a in allocations))
    
    # Calculate total students across all unique class sections
    total_students = 0
    unique_class_sections = set()
    
    for alloc in allocations:
        class_key = (alloc.dept, alloc.year, alloc.section)
        if class_key not in unique_class_sections:
            unique_class_sections.add(class_key)
            
            # Get the appropriate student model for this department
            student_model = get_student_model(alloc.dept)
            if student_model:
                # Use dept column for filtering as it is a string now
                count = db.query(student_model).filter(
                    student_model.year == alloc.year,
                    student_model.section == alloc.section
                ).count()
                total_students += count
    
    return schemas.FacultyDashboardStats(
        total_classes=total_classes,
        total_students=total_students,
        subjects_taught=subjects
    )

@router.get("/allocations", response_model=List[schemas.FacultyAllocationResponse])
async def get_faculty_allocations(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get all courses allocated to the current faculty member by HOD.
    """
    if current_user.role != models.RoleEnum.FACULTY:
        raise HTTPException(status_code=403, detail="Only faculty can access this endpoint")
    
    allocations = db.query(models.FacultyAllocation).filter(
        models.FacultyAllocation.faculty_id == current_user.user_id
    ).all()
    
    return allocations

@router.post("/schedule-quiz")
async def schedule_quiz(
    data: dict,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """Faculty schedules an early-risk quiz for a class before an assessment."""
    if current_user.role != models.RoleEnum.FACULTY:
        raise HTTPException(status_code=403, detail="Only faculty can schedule quizzes")
    
    # Verify faculty is allocated to this class
    alloc = db.query(models.FacultyAllocation).filter(
        models.FacultyAllocation.faculty_id == current_user.user_id,
        models.FacultyAllocation.dept == data.get("dept"),
        models.FacultyAllocation.year == data.get("year"),
        models.FacultyAllocation.section == data.get("section"),
        models.FacultyAllocation.subject_code == data.get("subject_code"),
    ).first()
    
    if not alloc:
        raise HTTPException(status_code=403, detail="You are not allocated to this class/subject")
    
    from datetime import datetime, timedelta
    deadline_str = data.get("deadline")
    try:
        # Parse input (assumed to be IST/local time from frontend)
        # Convert from IST to UTC for consistent storage in database
        deadline = datetime.fromisoformat(deadline_str.replace('Z', ''))
        if deadline.tzinfo is None:
            # Assume IST (+5:30) and convert to UTC by subtracting 5:30
            deadline = deadline - timedelta(hours=5, minutes=30)
    except (TypeError, ValueError):
        raise HTTPException(status_code=400, detail="Invalid deadline format. Use ISO format: YYYY-MM-DDTHH:MM:SS")
        
    start_time_str = data.get("start_time")
    start_time = None
    if start_time_str:
        try:
            # Parse input (assumed to be IST/local time from frontend)
            # Convert from IST to UTC for consistent storage
            start_time = datetime.fromisoformat(start_time_str.replace('Z', ''))
            if start_time.tzinfo is None:
                # Assume IST (+5:30) and convert to UTC by subtracting 5:30
                start_time = start_time - timedelta(hours=5, minutes=30)
        except (TypeError, ValueError):
            pass # Ignore invalid start times and let it be null

    scheduled = models.ScheduledQuiz(
        faculty_id=current_user.user_id,
        dept=data["dept"],
        year=data["year"],
        section=data["section"],
        subject_code=data["subject_code"],
        subject_title=data.get("subject_title", alloc.subject_title),
        unit_number=data.get("unit_number", 1),
        assessment_type=data.get("assessment_type", "CIA"),
        start_time=start_time,
        deadline=deadline,
    )
    db.add(scheduled)
    db.commit()
    db.refresh(scheduled)
    
    return {
        "id": scheduled.id,
        "message": f"Quiz scheduled for {scheduled.dept} Year {scheduled.year} {scheduled.section} - Unit {scheduled.unit_number} before {scheduled.assessment_type}",
        "start_time": scheduled.start_time.isoformat() if scheduled.start_time else None,
        "deadline": scheduled.deadline.isoformat()
    }

@router.get("/scheduled-quizzes")
async def get_scheduled_quizzes(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """Get all quizzes scheduled by this faculty."""
    if current_user.role != models.RoleEnum.FACULTY:
        raise HTTPException(status_code=403, detail="Only faculty can access this endpoint")
    
    quizzes = db.query(models.ScheduledQuiz).filter(
        models.ScheduledQuiz.faculty_id == current_user.user_id
    ).order_by(models.ScheduledQuiz.deadline.desc()).all()
    
    return [
        {
            "id": q.id,
            "dept": q.dept,
            "year": q.year,
            "section": q.section,
            "subject_code": q.subject_code,
            "subject_title": q.subject_title,
            "unit_number": q.unit_number,
            "assessment_type": q.assessment_type,
            "deadline": q.deadline.isoformat() if q.deadline else None,
            "is_active": q.is_active,
            "created_at": q.created_at.isoformat() if q.created_at else None,
        }
        for q in quizzes
    ]

@router.put("/scheduled-quizzes/{quiz_id}/close")
async def close_scheduled_quiz(
    quiz_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """Deactivate/close a scheduled quiz."""
    if current_user.role != models.RoleEnum.FACULTY:
        raise HTTPException(status_code=403, detail="Only faculty can access this endpoint")
    
    quiz = db.query(models.ScheduledQuiz).filter(
        models.ScheduledQuiz.id == quiz_id,
        models.ScheduledQuiz.faculty_id == current_user.user_id
    ).first()
    
    if not quiz:
        raise HTTPException(status_code=404, detail="Scheduled quiz not found")
    
    quiz.is_active = 0
    db.commit()
    
    return {"status": "success", "message": "Quiz closed"}

@router.put("/scheduled-quizzes/{quiz_id}")
async def update_scheduled_quiz(
    quiz_id: int,
    data: dict,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """Update a scheduled quiz's details."""
    if current_user.role != models.RoleEnum.FACULTY:
        raise HTTPException(status_code=403, detail="Only faculty can access this endpoint")
    
    quiz = db.query(models.ScheduledQuiz).filter(
        models.ScheduledQuiz.id == quiz_id,
        models.ScheduledQuiz.faculty_id == current_user.user_id
    ).first()
    
    if not quiz:
        raise HTTPException(status_code=404, detail="Scheduled quiz not found")
    
    # Update fields
    if "unit_number" in data:
        quiz.unit_number = int(data["unit_number"])
    if "assessment_type" in data:
        quiz.assessment_type = data["assessment_type"]
    
    from datetime import datetime, timedelta
    if "deadline" in data:
        try:
            deadline = datetime.fromisoformat(data["deadline"].replace('Z', ''))
            if deadline.tzinfo is None:
                deadline = deadline - timedelta(hours=5, minutes=30) # IST to UTC
            quiz.deadline = deadline
        except (TypeError, ValueError):
            pass
            
    if "start_time" in data:
        try:
            if data["start_time"]:
                st = datetime.fromisoformat(data["start_time"].replace('Z', ''))
                if st.tzinfo is None:
                    st = st - timedelta(hours=5, minutes=30) # IST to UTC
                quiz.start_time = st
            else:
                quiz.start_time = None
        except (TypeError, ValueError):
            pass

    db.commit()
    return {"status": "success", "message": "Quiz updated successfully"}

@router.delete("/scheduled-quizzes/{quiz_id}")
async def delete_scheduled_quiz(
    quiz_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """Delete a scheduled quiz."""
    if current_user.role != models.RoleEnum.FACULTY:
        raise HTTPException(status_code=403, detail="Only faculty can access this endpoint")
    
    quiz = db.query(models.ScheduledQuiz).filter(
        models.ScheduledQuiz.id == quiz_id,
        models.ScheduledQuiz.faculty_id == current_user.user_id
    ).first()
    
    if not quiz:
        raise HTTPException(status_code=404, detail="Scheduled quiz not found")
    
    db.delete(quiz)
    db.commit()
    
    return {"status": "success", "message": "Quiz deleted successfully"}

@router.get("/scheduled-quizzes/{quiz_id}/status", response_model=schemas.QuizStatusResponse)
async def get_scheduled_quiz_status(
    quiz_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """Get the status of all students for a specific scheduled quiz."""
    if current_user.role != models.RoleEnum.FACULTY:
        raise HTTPException(status_code=403, detail="Only faculty can access this endpoint")
    
    quiz = db.query(models.ScheduledQuiz).filter(
        models.ScheduledQuiz.id == quiz_id,
        models.ScheduledQuiz.faculty_id == current_user.user_id
    ).first()
    
    if not quiz:
        raise HTTPException(status_code=404, detail="Scheduled quiz not found")
    
    # Get the student model for the department
    student_model = get_student_model(quiz.dept)
    if not student_model:
        raise HTTPException(status_code=404, detail=f"Department {quiz.dept} student table not found")
    
    # Fetch all students in this class
    students_in_class = db.query(student_model).filter(
        student_model.year == quiz.year,
        student_model.section == quiz.section
    ).all()
    
    # Fetch all attempts for this quiz
    attempts = db.query(models.StudentQuizAttempt).filter(
        models.StudentQuizAttempt.scheduled_quiz_id == quiz_id
    ).all()
    
    # Map attempts by reg_no
    attempts_map = {a.reg_no: a for a in attempts}
    
    student_statuses = []
    completed_count = 0
    
    for s in students_in_class:
        attempt = attempts_map.get(s.reg_no)
        status = "Completed" if attempt else "Pending"
        if attempt:
            completed_count += 1
            
        student_statuses.append(schemas.StudentQuizStatus(
            reg_no=s.reg_no,
            name=s.name,
            status=status,
            score=attempt.score if attempt else None,
            attempted_at=attempt.attempted_at if attempt else None
        ))
        
    return schemas.QuizStatusResponse(
        quiz_id=quiz_id,
        subject_title=quiz.subject_title,
        total_students=len(students_in_class),
        completed_count=completed_count,
        pending_count=len(students_in_class) - completed_count,
        students=student_statuses
    )

@router.get("/class-quiz-scores", response_model=schemas.ClassQuizScoresResponse)
async def get_class_quiz_scores(
    dept: str,
    year: int,
    section: str,
    subject_code: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """Get all student scores for a specific class and subject across all units."""
    if current_user.role != models.RoleEnum.FACULTY:
        raise HTTPException(status_code=403, detail="Only faculty can access scores")
    
    # Get faculty allocation to verify ownership and get subject title
    alloc = db.query(models.FacultyAllocation).filter(
        models.FacultyAllocation.faculty_id == current_user.user_id,
        models.FacultyAllocation.dept == dept,
        models.FacultyAllocation.year == year,
        models.FacultyAllocation.section == section,
        models.FacultyAllocation.subject_code == subject_code
    ).first()
    
    if not alloc:
        raise HTTPException(status_code=403, detail="You are not authorized for this class/subject")

    # Get students
    student_model = get_student_model(dept)
    if not student_model:
        raise HTTPException(status_code=400, detail="Invalid department")
    
    students = db.query(student_model).filter(
        student_model.year == int(year),
        student_model.section == section
    ).all()
    
    reg_nos = [s.reg_no for s in students]
    
    # Get all attempts
    # Subquery to find max date per student per unit
    subquery = db.query(
        models.StudentQuizAttempt.reg_no,
        models.StudentQuizAttempt.unit,
        func.max(models.StudentQuizAttempt.attempted_at).label('max_date')
    ).filter(
        models.StudentQuizAttempt.reg_no.in_(reg_nos),
        models.StudentQuizAttempt.subject == subject_code
    ).group_by(
        models.StudentQuizAttempt.reg_no,
        models.StudentQuizAttempt.unit
    ).subquery()
    
    latest_attempts = db.query(models.StudentQuizAttempt).join(
        subquery,
        (models.StudentQuizAttempt.reg_no == subquery.c.reg_no) &
        (models.StudentQuizAttempt.unit == subquery.c.unit) &
        (models.StudentQuizAttempt.attempted_at == subquery.c.max_date)
    ).all()
    
    # Map by reg_no -> unit -> score
    scores_map = {}
    for a in latest_attempts:
        if a.reg_no not in scores_map:
            scores_map[a.reg_no] = {}
        scores_map[a.reg_no][str(a.unit)] = a.score
    
    result_students = []
    for s in students:
        student_scores = scores_map.get(s.reg_no, {})
        # Ensure all units 1-5 exist (even if null)
        final_scores = {str(u): student_scores.get(str(u)) for u in range(1, 6)}
        
        result_students.append(schemas.StudentUnitScore(
            reg_no=s.reg_no,
            name=s.name,
            scores=final_scores
        ))
    
    return schemas.ClassQuizScoresResponse(
        dept=dept,
        year=year,
        section=section,
        subject_code=subject_code,
        subject_title=alloc.subject_title,
        students=result_students
    )

