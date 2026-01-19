from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from typing import List, Optional
from database import get_db
from datetime import date
import models
import schemas
from auth import get_current_active_user

router = APIRouter(
    prefix="/api/timetable",
    tags=["timetable"]
)

@router.get("/{dept}/{year}/{section}", response_model=List[schemas.TimetableResponse])
async def get_class_timetable(
    dept: str,
    year: int,
    section: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get the regular weekly timetable for a specific class.
    If student, checks if published.
    """
    
    # Check published status if student
    if current_user.role == models.RoleEnum.STUDENT:
        if current_user.dept != dept or int(current_user.year or 0) != year or current_user.section != section:
             raise HTTPException(status_code=403, detail="Not authorized to view this timetable")

        status = db.query(models.TimetableStatus).filter(
            models.TimetableStatus.dept == dept,
            models.TimetableStatus.year == year,
            models.TimetableStatus.section == section
        ).first()
        
        if not status or status.is_published == 0:
            raise HTTPException(status_code=403, detail="Timetable not published yet")

    # Fetch regular entries only
    query = db.query(models.Timetable).filter(
        models.Timetable.dept == dept,
        models.Timetable.year == year,
        models.Timetable.section == section
    )

    return query.all()

@router.delete("/{dept}/{year}/{section}/{day}/{period}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_timetable_entry(
    dept: str,
    year: int,
    section: str,
    day: str,
    period: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Delete a timetable entry.
    """
    entry = db.query(models.Timetable).filter(
        models.Timetable.dept == dept,
        models.Timetable.year == year,
        models.Timetable.section == section,
        models.Timetable.day == day,
        models.Timetable.period == period
    ).first()

    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")

    db.delete(entry)
    db.commit()
    return None

@router.post("/", response_model=schemas.TimetableResponse)
async def create_or_update_timetable_entry(
    entry: schemas.TimetableCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Create or update a timetable entry.
    """
    existing_entry = db.query(models.Timetable).filter(
        models.Timetable.dept == entry.dept,
        models.Timetable.year == entry.year,
        models.Timetable.section == entry.section,
        models.Timetable.day == entry.day,
        models.Timetable.period == entry.period
    ).first()

    if existing_entry:
        existing_entry.subject_code = entry.subject_code
        existing_entry.subject_title = entry.subject_title
        existing_entry.duration = entry.duration
        existing_entry.day = entry.day
             
        db.commit()
        db.refresh(existing_entry)
        return existing_entry
    else:
        new_entry = models.Timetable(
            dept=entry.dept,
            year=entry.year,
            section=entry.section,
            day=entry.day,
            period=entry.period,
            subject_code=entry.subject_code,
            subject_title=entry.subject_title,
            duration=entry.duration
        )
        db.add(new_entry)
        db.commit()
        db.refresh(new_entry)
        return new_entry

@router.post("/publish", response_model=schemas.TimetableStatusResponse)
async def publish_timetable(
    status_update: schemas.TimetableStatusBase,
    dept: str, 
    year: int, 
    section: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    status_entry = db.query(models.TimetableStatus).filter(
        models.TimetableStatus.dept == dept,
        models.TimetableStatus.year == year,
        models.TimetableStatus.section == section
    ).first()
    
    if status_entry:
        status_entry.is_published = status_update.is_published
    else:
        status_entry = models.TimetableStatus(
            dept=dept,
            year=year,
            section=section,
            is_published=status_update.is_published
        )
        db.add(status_entry)
    
    db.commit()
    db.refresh(status_entry)
    return status_entry

@router.get("/status/{dept}/{year}/{section}", response_model=schemas.TimetableStatusResponse)
async def get_publish_status(
    dept: str,
    year: int,
    section: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    status_entry = db.query(models.TimetableStatus).filter(
        models.TimetableStatus.dept == dept,
        models.TimetableStatus.year == year,
        models.TimetableStatus.section == section
    ).first()
    
    if not status_entry:
        return schemas.TimetableStatusResponse(
            dept=dept, year=year, section=section, is_published=0, updated_at=date.today()
        ) # Default
        
    return status_entry
