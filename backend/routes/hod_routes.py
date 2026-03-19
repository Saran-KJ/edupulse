from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models
import schemas
from auth import get_current_active_user
from routes.project_routes import seed_project_tasks

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
    # Robustly get the role string value
    user_role = current_user.role
    if hasattr(user_role, 'value'):
        user_role = user_role.value
    user_role = str(user_role).lower()
    
    if user_role not in ["hod", "faculty", "admin", "class_advisor"] and "faculty" not in user_role:
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access denied for role {user_role}"
        )
    
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

@router.post("/subject-selection", response_model=List[schemas.SubjectSelectionResponse])
async def create_subject_selections(
    selections: List[schemas.SubjectSelectionCreate],
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Save Subject Selections for a specific class (Sem 5-7).
    Replaces existing selections for that class and semester.
    """
    check_hod_role(current_user)
    if not selections:
        return []
        
    dept = selections[0].dept
    year = selections[0].year
    section = selections[0].section
    semester = selections[0].semester

    # Delete existing selections to replace them
    db.query(models.SubjectSelection).filter(
        models.SubjectSelection.dept == dept,
        models.SubjectSelection.year == year,
        models.SubjectSelection.section == section,
        models.SubjectSelection.semester == semester
    ).delete()
    
    db_selections = [models.SubjectSelection(**sel.model_dump()) for sel in selections]
    db.add_all(db_selections)
    db.commit()
    
    # Return saved
    saved = db.query(models.SubjectSelection).filter(
        models.SubjectSelection.dept == dept,
        models.SubjectSelection.year == year,
        models.SubjectSelection.section == section,
        models.SubjectSelection.semester == semester
    ).all()
    return saved

@router.get("/subject-selection/{dept}/{year}/{section}/{semester}", response_model=List[schemas.SubjectSelectionResponse])
async def get_subject_selections(
    dept: str,
    year: int,
    section: str,
    semester: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """Get subject selections for a class."""
    return db.query(models.SubjectSelection).filter(
        models.SubjectSelection.dept == dept,
        models.SubjectSelection.year == year,
        models.SubjectSelection.section == section,
        models.SubjectSelection.semester == semester
    ).all()

@router.delete("/subject-selection/{id}")
async def delete_subject_selection(
    id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """Delete a single subject selection."""
    check_hod_role(current_user)
    selection = db.query(models.SubjectSelection).filter(models.SubjectSelection.id == id).first()
    if not selection:
        raise HTTPException(status_code=404, detail="Subject selection not found")
    db.delete(selection)
    db.commit()
    return {"message": "Subject selection deleted"}

@router.post("/batches/create", response_model=schemas.ProjectBatchResponse)
async def create_project_batch(
    batch: schemas.ProjectBatchCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Create a new project batch with assigned guide and 1-4 students.
    """
    check_hod_role(current_user)
    
    # 1. Validate student count
    if not batch.student_reg_nos or len(batch.student_reg_nos) < 1 or len(batch.student_reg_nos) > 4:
        raise HTTPException(status_code=400, detail="A batch must have between 1 and 4 students.")

    # 2. Check if guide exists
    guide = db.query(models.User).filter(models.User.user_id == batch.guide_id, models.User.role == models.RoleEnum.FACULTY).first()
    if not guide:
        raise HTTPException(status_code=404, detail="Assigned guide not found or is not a faculty member.")

    # 3. Validation: Unique students mapping
    resolved_student_user_ids = []
    for reg_no in batch.student_reg_nos:
        # Resolve to User record via reg_no directly
        student_user = db.query(models.User).filter(
            models.User.reg_no == reg_no, 
            models.User.role == models.RoleEnum.STUDENT
        ).first()
        
        if not student_user:
            raise HTTPException(status_code=404, detail=f"User record for student with registration number {reg_no} not found.")

        # Check if already in a batch
        existing_batch = db.query(models.ProjectBatchStudent).filter(models.ProjectBatchStudent.student_id == student_user.user_id).first()
        if existing_batch:
            raise HTTPException(status_code=400, detail=f"Student {student_user.name} ({student_user.reg_no}) is already assigned to a batch.")
            
        resolved_student_user_ids.append(student_user.user_id)

    # 4. Create Batch
    new_batch = models.ProjectBatch(
        guide_id=batch.guide_id,
        dept=batch.dept,
        year=batch.year,
        section=batch.section,
        created_by=current_user.user_id
    )
    db.add(new_batch)
    db.commit()
    db.refresh(new_batch)

    # 5. Add Students
    batch_students = []
    for user_id in resolved_student_user_ids:
        bs = models.ProjectBatchStudent(
            batch_id=new_batch.id,
            student_id=user_id
        )
        db.add(bs)
        batch_students.append(bs)

    db.commit()

    # Seed roadmap tasks for the new batch
    seed_project_tasks(db, new_batch.id)

    # 6. Prepare Response
    db.refresh(new_batch)
    student_responses = []
    
    for bs in new_batch.students:
        s = bs.student
        student_responses.append(schemas.ProjectBatchStudentResponse(
            student_id=s.user_id,
            name=s.name,
            reg_no=s.reg_no,
            email=s.email,
            phone=s.phone
        ))

    return schemas.ProjectBatchResponse(
        id=new_batch.id,
        guide_id=guide.user_id,
        guide_name=guide.name,
        dept=new_batch.dept,
        year=new_batch.year,
        section=new_batch.section,
        students=student_responses,
        created_at=new_batch.created_at
    )

@router.get("/batches", response_model=List[schemas.ProjectBatchResponse])
async def get_all_batches(
    dept: Optional[str] = None,
    year: Optional[int] = None,
    section: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Fetch all batches. HOD can see all batches (filtered optionally by class). Also accessible to faculty coordinators.
    """
    # Robustly get the role string value
    user_role = current_user.role
    if hasattr(user_role, 'value'):
        user_role = user_role.value
    user_role = str(user_role).lower()
    
    if user_role not in ["hod", "faculty", "admin", "class_advisor"] and "faculty" not in user_role:
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access denied for role {user_role}"
        )
    
    query = db.query(models.ProjectBatch)
    if dept:
        query = query.filter(models.ProjectBatch.dept == dept)
    if year:
        query = query.filter(models.ProjectBatch.year == year)
    if section:
        query = query.filter(models.ProjectBatch.section == section)
        
    batches = query.order_by(models.ProjectBatch.created_at.desc()).all()
    
    result = []
    for batch in batches:
        st_resp = []
        for bs in batch.students:
             st_resp.append(schemas.ProjectBatchStudentResponse(
                 student_id=bs.student.user_id,
                 name=bs.student.name,
                 reg_no=bs.student.reg_no,
                 email=bs.student.email,
                 phone=bs.student.phone
             ))
        
        result.append(schemas.ProjectBatchResponse(
            id=batch.id,
            guide_id=batch.guide.user_id,
            guide_name=batch.guide.name,
            dept=batch.dept,
            year=batch.year,
            section=batch.section,
            students=st_resp,
            created_at=batch.created_at
        ))
    return result

@router.post("/coordinator", response_model=schemas.ProjectCoordinatorResponse)
async def assign_project_coordinator(
    coord: schemas.ProjectCoordinatorCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Assign a faculty member as a Project Coordinator for a specific department and year.
    Only HODs can assign coordinators.
    """
    check_hod_role(current_user)
    
    # Verify faculty exists
    faculty = db.query(models.User).filter(
        models.User.user_id == coord.faculty_id,
        models.User.role == models.RoleEnum.FACULTY
    ).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty member not found")

    # Check if this specific faculty is already assigned for this dept/year
    existing = db.query(models.ProjectCoordinator).filter(
        models.ProjectCoordinator.faculty_id == coord.faculty_id,
        models.ProjectCoordinator.dept == coord.dept,
        models.ProjectCoordinator.year == coord.year
    ).first()
    
    if existing:
        return schemas.ProjectCoordinatorResponse(
            id=existing.id,
            faculty_id=existing.faculty_id,
            faculty_name=faculty.name,
            dept=existing.dept,
            year=existing.year,
            created_at=existing.created_at
        )

    # Check how many coordinators are already assigned
    count = db.query(models.ProjectCoordinator).filter(
        models.ProjectCoordinator.dept == coord.dept,
        models.ProjectCoordinator.year == coord.year
    ).count()
    
    if count >= 2:
        raise HTTPException(status_code=400, detail="Maximum 2 coordinators allowed per year/department")

    new_coord = models.ProjectCoordinator(**coord.model_dump())

    db.add(new_coord)
    db.commit()
    db.refresh(new_coord)
    
    return schemas.ProjectCoordinatorResponse(
        id=new_coord.id,
        faculty_id=new_coord.faculty_id,
        faculty_name=faculty.name,
        dept=new_coord.dept,
        year=new_coord.year,
        created_at=new_coord.created_at
    )

@router.get("/coordinators/{dept}", response_model=List[schemas.ProjectCoordinatorResponse])
async def get_project_coordinators(
    dept: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get all project coordinators for a department.
    """
    # Robustly get the role string value
    user_role = current_user.role
    if hasattr(user_role, 'value'):
        user_role = user_role.value
    user_role = str(user_role).lower()
    
    if user_role not in ["hod", "faculty", "admin", "class_advisor"] and "faculty" not in user_role:
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access denied for role {user_role}"
        )
    
    coords = db.query(models.ProjectCoordinator).filter(models.ProjectCoordinator.dept == dept).all()
    
    result = []
    for c in coords:
        result.append(schemas.ProjectCoordinatorResponse(
            id=c.id,
            faculty_id=c.faculty_id,
            faculty_name=c.faculty.name,
            dept=c.dept,
            year=c.year,
            created_at=c.created_at
        ))
    return result

@router.delete("/coordinator/{coord_id}")
async def delete_project_coordinator(
    coord_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Remove a faculty member from the Project Coordinator role.
    Only HODs can delete coordinators.
    """
    check_hod_role(current_user)
    
    coord = db.query(models.ProjectCoordinator).filter(models.ProjectCoordinator.id == coord_id).first()
    if not coord:
        raise HTTPException(status_code=404, detail="Project coordinator not found")
    
    db.delete(coord)
    db.commit()
    
    return {"message": "Coordinator removed successfully"}

@router.put("/coordinator/{coord_id}", response_model=schemas.ProjectCoordinatorResponse)
async def update_project_coordinator(
    coord_id: int,
    coord: schemas.ProjectCoordinatorCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Update a project coordinator assignment.
    Only HODs can update coordinators.
    """
    check_hod_role(current_user)
    
    db_coord = db.query(models.ProjectCoordinator).filter(models.ProjectCoordinator.id == coord_id).first()
    if not db_coord:
        raise HTTPException(status_code=404, detail="Project coordinator not found")
    
    # Verify new faculty exists
    faculty = db.query(models.User).filter(
        models.User.user_id == coord.faculty_id,
        models.User.role == models.RoleEnum.FACULTY
    ).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty member not found")

    # Check if this faculty is already assigned as another coordinator for this dept/year
    other_existing = db.query(models.ProjectCoordinator).filter(
        models.ProjectCoordinator.faculty_id == coord.faculty_id,
        models.ProjectCoordinator.dept == db_coord.dept,
        models.ProjectCoordinator.year == db_coord.year,
        models.ProjectCoordinator.id != coord_id
    ).first()
    
    if other_existing:
        raise HTTPException(status_code=400, detail="This faculty is already assigned as a coordinator for this year")

    db_coord.faculty_id = coord.faculty_id
    db.commit()
    db.refresh(db_coord)
    
    return schemas.ProjectCoordinatorResponse(
        id=db_coord.id,
        faculty_id=db_coord.faculty_id,
        faculty_name=faculty.name,
        dept=db_coord.dept,
        year=db_coord.year,
        created_at=db_coord.created_at
    )

