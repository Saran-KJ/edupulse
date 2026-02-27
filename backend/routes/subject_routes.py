from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models
import schemas
import auth

router = APIRouter(prefix="/api/subjects", tags=["Subjects"])


@router.get("", response_model=List[schemas.SubjectResponse])
async def get_subjects(
    semester: Optional[str] = None,
    category: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """
    Get all subjects with optional filters.
    - semester: I, II, III, IV, V, VI, VII, VIII, PEC, OEC
    - category: CORE, LAB, PEC, OEC, EEC
    """
    query = db.query(models.Subject)

    if semester:
        query = query.filter(models.Subject.semester == semester)
    if category:
        query = query.filter(models.Subject.category == category.upper())

    subjects = query.order_by(models.Subject.id).all()
    return subjects


@router.get("/{subject_code}", response_model=schemas.SubjectResponse)
async def get_subject_by_code(
    subject_code: str,
    db: Session = Depends(get_db),
):
    """Get a single subject by its subject code."""
    subject = db.query(models.Subject).filter(
        models.Subject.subject_code == subject_code
    ).first()

    if not subject:
        raise HTTPException(status_code=404, detail=f"Subject '{subject_code}' not found")

    return subject
