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
        # Normalize: accept both roman ("VII") and numeric ("7") by checking both forms
        roman_to_num = {
            "I": "1", "II": "2", "III": "3", "IV": "4",
            "V": "5", "VI": "6", "VII": "7", "VIII": "8"
        }
        num_to_roman = {v: k for k, v in roman_to_num.items()}
        
        # Build list of equivalent values to match against
        sem_variants = {semester}
        if semester in roman_to_num:
            sem_variants.add(roman_to_num[semester])
        elif semester in num_to_roman:
            sem_variants.add(num_to_roman[semester])
        
        query = query.filter(models.Subject.semester.in_(sem_variants))

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
