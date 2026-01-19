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
    
    return created_marks

@router.get("/class/{dept}/{year}/{section}", response_model=List[schemas.MarkResponse])
async def get_class_marks(
    dept: str,
    year: int,
    section: str,
    semester: Optional[int] = None,
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
    
    db.delete(db_mark)
    db.commit()
    return {"message": "Mark deleted successfully"}

@router.get("/student/{reg_no}", response_model=List[schemas.MarkResponse])
async def get_student_marks(
    reg_no: str,
    semester: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """Get all marks for a specific student"""
    query = db.query(models.Mark).filter(models.Mark.reg_no == reg_no)
    
    if semester:
        query = query.filter(models.Mark.semester == semester)
    
    marks = query.all()
    return marks
