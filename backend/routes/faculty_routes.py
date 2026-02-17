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
