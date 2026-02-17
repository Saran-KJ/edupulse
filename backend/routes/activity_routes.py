from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from database import get_db
import models
import schemas
import auth

router = APIRouter(prefix="/api/activities", tags=["Activities"])

@router.post("", response_model=schemas.ActivityResponse)
async def create_activity(
    activity: schemas.ActivityCreate,
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
    db_activity = models.Activity(**activity.dict())
    db.add(db_activity)
    db.commit()
    db.refresh(db_activity)
    return db_activity

@router.get("", response_model=List[schemas.ActivityResponse])
async def get_activities(
    skip: int = 0,
    limit: int = 100,
    activity_type: Optional[models.ActivityTypeEnum] = None,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    query = db.query(models.Activity)
    
    if activity_type:
        query = query.filter(models.Activity.activity_type == activity_type)
    
    activities = query.offset(skip).limit(limit).all()
    return activities

# ===== Student Activity Submission Endpoints =====
# These MUST be defined before /{activity_id} to avoid path conflicts

@router.post("/submit", response_model=schemas.StudentActivitySubmissionResponse)
async def submit_activity(
    submission: schemas.StudentActivitySubmissionCreate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([models.RoleEnum.STUDENT]))
):
    """Student submits an activity for approval"""
    if not current_user.reg_no or not current_user.dept:
        raise HTTPException(status_code=400, detail="Student profile incomplete (missing reg_no or dept)")
    
    db_submission = models.StudentActivitySubmission(
        reg_no=current_user.reg_no,
        activity_name=submission.activity_name,
        activity_type=submission.activity_type,
        level=submission.level,
        activity_date=submission.activity_date,
        description=submission.description,
        role=submission.role,
        achievement=submission.achievement,
        dept=current_user.dept,
        year=int(current_user.year) if current_user.year else 1,
        section=current_user.section or "A",
        status="pending"
    )
    db.add(db_submission)
    db.commit()
    db.refresh(db_submission)
    return db_submission

@router.get("/my-submissions", response_model=List[schemas.StudentActivitySubmissionResponse])
async def get_my_submissions(
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([models.RoleEnum.STUDENT]))
):
    """Student gets their own activity submissions"""
    if not current_user.reg_no:
        raise HTTPException(status_code=400, detail="Student profile incomplete")
    
    submissions = db.query(models.StudentActivitySubmission).filter(
        models.StudentActivitySubmission.reg_no == current_user.reg_no
    ).order_by(models.StudentActivitySubmission.created_at.desc()).all()
    return submissions

@router.get("/student/{reg_no}", response_model=List[schemas.StudentActivitySubmissionResponse])
async def get_student_submissions(
    reg_no: str,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    """
    Get activity submissions for a specific student.
    Allowed for:
    - The student themselves (if reg_no matches)
    - Parents (if child_reg_no matches)
    - Faculty/Admin (generally allowed)
    """
    # Authorization check
    if current_user.role == models.RoleEnum.STUDENT and current_user.reg_no != reg_no:
        raise HTTPException(status_code=403, detail="Cannot view other students' activities")
        
    if current_user.role == models.RoleEnum.PARENT:
        if current_user.child_reg_no != reg_no:
             # Fallback to phone check or strict error
             raise HTTPException(status_code=403, detail="Cannot view other students' activities")

    submissions = db.query(models.StudentActivitySubmission).filter(
        models.StudentActivitySubmission.reg_no == reg_no
    ).order_by(models.StudentActivitySubmission.created_at.desc()).all()
    return submissions

@router.get("/pending-submissions/{dept}/{year}/{section}", response_model=List[schemas.StudentActivitySubmissionResponse])
async def get_pending_submissions(
    dept: str,
    year: int,
    section: str,
    status: Optional[str] = "pending",
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.ADMIN,
        models.RoleEnum.HOD,
        models.RoleEnum.PRINCIPAL
    ]))
):
    """Class advisor gets pending activity submissions for their class"""
    query = db.query(models.StudentActivitySubmission).filter(
        models.StudentActivitySubmission.dept == dept.upper(),
        models.StudentActivitySubmission.year == year,
        models.StudentActivitySubmission.section == section.upper()
    )
    if status:
        query = query.filter(models.StudentActivitySubmission.status == status)
    
    submissions = query.order_by(models.StudentActivitySubmission.created_at.desc()).all()
    return submissions

@router.put("/submissions/{submission_id}/review", response_model=schemas.StudentActivitySubmissionResponse)
async def review_submission(
    submission_id: int,
    review: schemas.StudentActivitySubmissionReview,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.ADMIN,
        models.RoleEnum.HOD,
        models.RoleEnum.PRINCIPAL
    ]))
):
    """Class advisor approves or rejects a student activity submission"""
    submission = db.query(models.StudentActivitySubmission).filter(
        models.StudentActivitySubmission.id == submission_id
    ).first()
    
    if not submission:
        raise HTTPException(status_code=404, detail="Submission not found")
    
    if submission.status != "pending":
        raise HTTPException(status_code=400, detail="Submission already reviewed")
    
    if review.status not in ("approved", "rejected"):
        raise HTTPException(status_code=400, detail="Status must be 'approved' or 'rejected'")
    
    submission.status = review.status
    submission.reviewer_id = current_user.user_id
    submission.review_comment = review.review_comment
    
    # On approval, auto-create Activity + ActivityParticipation
    if review.status == "approved":
        db_activity = models.Activity(
            activity_name=submission.activity_name,
            activity_type=submission.activity_type,
            level=submission.level,
            activity_date=submission.activity_date,
            description=submission.description,
        )
        db.add(db_activity)
        db.flush()  # Get the activity_id
        
        db_participation = models.ActivityParticipation(
            activity_id=db_activity.activity_id,
            reg_no=submission.reg_no,
            role=submission.role,
            achievement=submission.achievement,
        )
        db.add(db_participation)
    
    db.commit()
    db.refresh(submission)
    return submission

# ===== Existing Activity Endpoints (parameterized routes) =====

@router.get("/{activity_id}", response_model=schemas.ActivityResponse)
async def get_activity(
    activity_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    activity = db.query(models.Activity).filter(
        models.Activity.activity_id == activity_id
    ).first()
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
    return activity

@router.put("/{activity_id}", response_model=schemas.ActivityResponse)
async def update_activity(
    activity_id: int,
    activity_update: schemas.ActivityUpdate,
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
    activity = db.query(models.Activity).filter(
        models.Activity.activity_id == activity_id
    ).first()
    
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
        
    if activity_update.activity_name is not None:
        activity.activity_name = activity_update.activity_name
    if activity_update.activity_type is not None:
        activity.activity_type = activity_update.activity_type
    if activity_update.level is not None:
        activity.level = activity_update.level
    if activity_update.activity_date is not None:
        activity.activity_date = activity_update.activity_date
    if activity_update.description is not None:
        activity.description = activity_update.description
        
    db.commit()
    db.refresh(activity)
    return activity

@router.post("/participation", response_model=schemas.ActivityParticipationResponse)
async def create_participation(
    participation: schemas.ActivityParticipationCreate,
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
    db_participation = models.ActivityParticipation(**participation.dict())
    db.add(db_participation)
    db.commit()
    db.refresh(db_participation)
    return db_participation

@router.get("/participation/student/{student_id}", response_model=List[schemas.ActivityParticipationResponse])
async def get_student_participations(
    student_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.get_current_active_user)
):
    participations = db.query(models.ActivityParticipation).filter(
        models.ActivityParticipation.student_id == student_id
    ).all()
    return participations

@router.delete("/participation/{participation_id}")
async def delete_participation(
    participation_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.PRINCIPAL
    ]))
):
    participation = db.query(models.ActivityParticipation).filter(
        models.ActivityParticipation.participation_id == participation_id
    ).first()
    
    if not participation:
        raise HTTPException(status_code=404, detail="Participation not found")
        
    db.delete(participation)
    db.commit()
    return {"message": "Participation deleted successfully"}

@router.put("/participation/{participation_id}", response_model=schemas.ActivityParticipationResponse)
async def update_participation(
    participation_id: int,
    update_data: schemas.ActivityParticipationUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.FACULTY,
        models.RoleEnum.HOD,
        models.RoleEnum.PRINCIPAL
    ]))
):
    participation = db.query(models.ActivityParticipation).filter(
        models.ActivityParticipation.participation_id == participation_id
    ).first()
    
    if not participation:
        raise HTTPException(status_code=404, detail="Participation not found")
        
    if update_data.role is not None:
        participation.role = update_data.role
    if update_data.achievement is not None:
        participation.achievement = update_data.achievement
        
    db.commit()
    db.refresh(participation)
    return participation

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

@router.get("/class/{dept}/{year}/{section}", response_model=List[schemas.StudentWithActivities])
async def get_class_activities(
    dept: str,
    year: int,
    section: str,
    db: Session = Depends(get_db),
    current_user = Depends(auth.require_role([
        models.RoleEnum.ADMIN, 
        models.RoleEnum.CLASS_ADVISOR,
        models.RoleEnum.HOD,
        models.RoleEnum.PRINCIPAL
    ]))
):
    # Get the correct student model for the department
    student_model = get_student_model(dept)
    if not student_model:
        raise HTTPException(status_code=400, detail="Invalid department")

    # 1. Get all students in this class
    students = db.query(student_model).filter(
        student_model.year == year,
        student_model.section == section
    ).all()
    
    result = []
    for student in students:
        # 2. Get participations for each student using reg_no
        participations = db.query(models.ActivityParticipation).options(
            joinedload(models.ActivityParticipation.activity)
        ).filter(
            models.ActivityParticipation.reg_no == student.reg_no
        ).all()
        
        result.append({
            "student": student,
            "activities": participations
        })
        
    return result
