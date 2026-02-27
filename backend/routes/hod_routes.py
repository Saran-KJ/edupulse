from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models
import schemas
from auth import get_current_active_user

router = APIRouter(
    prefix="/api/hod",
    tags=["hod"]
)

# Helper to check if user is HOD
def check_hod_role(current_user: models.User):
    if current_user.role != models.RoleEnum.HOD:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only HODs can access this endpoint"
        )
    return current_user

@router.post("/allocations", response_model=schemas.FacultyAllocationResponse)
async def create_allocation(
    allocation: schemas.FacultyAllocationCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Create a new faculty allocation to a subject.
    Only HODs can create allocations.
    """
    check_hod_role(current_user)
    
    # Ensure HOD allows allocation only for their department ideally, 
    # but for now we'll just check role. 
    # Optional: Check if current_user.dept == allocation.dept
    
    # Check if allocation already exists for this subject/class
    # Depending on requirements, maybe multiple faculty can teach same subject (e.g. labs)?
    # For now assuming one faculty per subject per class section.
    existing = db.query(models.FacultyAllocation).filter(
        models.FacultyAllocation.dept == allocation.dept,
        models.FacultyAllocation.year == allocation.year,
        models.FacultyAllocation.section == allocation.section,
        models.FacultyAllocation.subject_code == allocation.subject_code
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Allocation already exists for this subject and class. Delete existing one first.")
    
    db_allocation = models.FacultyAllocation(**allocation.model_dump())
    db.add(db_allocation)
    db.commit()
    db.refresh(db_allocation)
    return db_allocation

@router.get("/allocations/{dept}/{year}/{section}", response_model=List[schemas.FacultyAllocationResponse])
async def get_allocations(
    dept: str,
    year: int,
    section: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get all allocations for a specific class.
    Accessible by HOD, Admin, Faculty.
    """
    # Relaxed permission for viewing, or restrict to HOD/Admin?
    # check_hod_role(current_user) 
    
    allocations = db.query(models.FacultyAllocation).filter(
        models.FacultyAllocation.dept == dept,
        models.FacultyAllocation.year == year,
        models.FacultyAllocation.section == section
    ).all()
    return allocations

@router.delete("/allocations/{id}")
async def delete_allocation(
    id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Delete an allocation.
    Only HODs can delete.
    """
    check_hod_role(current_user)
    
    allocation = db.query(models.FacultyAllocation).filter(models.FacultyAllocation.id == id).first()
    if not allocation:
        raise HTTPException(status_code=404, detail="Allocation not found")
        
    db.delete(allocation)
    db.commit()
    return {"message": "Allocation deleted successfully"}

@router.get("/faculty/{dept}", response_model=List[schemas.UserResponse])
async def get_department_faculty(
    dept: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get all faculty members for a specific department.
    """
    check_hod_role(current_user)
    
    faculty_members = db.query(models.User).filter(
        models.User.role == models.RoleEnum.FACULTY,
        models.User.dept == dept,
        models.User.is_active == 1,
        models.User.is_approved == 1
    ).all()
    
    return faculty_members

@router.get("/subjects/{semester}", response_model=List[schemas.SubjectResponse])
async def get_semester_subjects(
    semester: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get all subjects for a specific semester (I, II, III, IV, V, VI, VII, VIII, PEC, OEC).
    """
    check_hod_role(current_user)
    
    subjects = db.query(models.Subject).filter(
        models.Subject.semester == semester
    ).all()
    
    return subjects
