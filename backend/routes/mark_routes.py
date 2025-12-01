from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models
import schemas
import auth

router = APIRouter(prefix="/api/marks", tags=["Marks"])

@router.post("", response_model=schemas.MarkResponse)
async def create_mark(
    mark: schemas.MarkCreate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL
    ]))
):
    # Calculate total and grade
    total = mark.internal_marks + (mark.external_marks or 0)
    
    # Simple grade calculation
    if total >= 90:
        grade = "O"
    elif total >= 80:
        grade = "A+"
    elif total >= 70:
        grade = "A"
    elif total >= 60:
        grade = "B+"
    elif total >= 50:
        grade = "B"
    elif total >= 40:
        grade = "C"
    else:
        grade = "F"
    
    db_mark = models.Mark(
        **mark.dict(),
        total_marks=total,
        grade=grade
    )
    db.add(db_mark)
    db.commit()
    db.refresh(db_mark)
    return db_mark

@router.get("/student/{student_id}", response_model=List[schemas.MarkResponse])
async def get_student_marks(
    student_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    marks = db.query(models.Mark).filter(models.Mark.student_id == student_id).all()
    return marks

@router.get("/{mark_id}", response_model=schemas.MarkResponse)
async def get_mark(
    mark_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    mark = db.query(models.Mark).filter(models.Mark.mark_id == mark_id).first()
    if not mark:
        raise HTTPException(status_code=404, detail="Mark not found")
    return mark

@router.delete("/{mark_id}")
async def delete_mark(
    mark_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL
    ]))
):
    db_mark = db.query(models.Mark).filter(models.Mark.mark_id == mark_id).first()
    if not db_mark:
        raise HTTPException(status_code=404, detail="Mark not found")
    
    db.delete(db_mark)
    db.commit()
    return {"message": "Mark deleted successfully"}
