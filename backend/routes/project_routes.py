from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models
import schemas
from auth import get_current_active_user, require_role

router = APIRouter(
    prefix="/api/projects",
    tags=["Projects"]
)

# HELPER: Seed tasks for a new batch
def seed_project_tasks(db: Session, batch_id: int):
    tasks = [
        # Phase 1
        ("Phase 1", "Literature Survey (10-15 base papers)"),
        ("Phase 1", "Problem Definition & Scope"),
        ("Phase 1", "System Architecture & Design (DFD/UML)"),
        ("Phase 1", "Algorithm/Tech Stack Selection"),
        # Phase 2
        ("Phase 2", "Core Coding / Backend Implementation"),
        ("Phase 2", "Database Connection & Schema"),
        ("Phase 2", "Intermediate Results / UI Prototypes"),
        ("Phase 2", "Core Module Completion"),
        # Phase 3
        ("Phase 3", "System Testing (Unit & Integration)"),
        ("Phase 3", "Performance Metrics Generation"),
        ("Phase 3", "Comparative Analysis with Existing Systems"),
        ("Phase 3", "Paper Publication / Conference Submission"),
        ("Phase 3", "Final Project Report Draft"),
    ]
    for phase, name in tasks:
        db_task = models.ProjectTask(
            batch_id=batch_id,
            phase=phase,
            task_name=name,
            is_completed=0
        )
        db.add(db_task)
    db.commit()

@router.get("/my-batch", response_model=Optional[schemas.ProjectBatchResponse])
async def get_my_project_batch(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get the project batch details for the currently logged-in student.
    """
    if current_user.role != models.RoleEnum.STUDENT:
        raise HTTPException(status_code=400, detail="Only students can access this endpoint")
    
    # Find the batch this student belongs to
    link = db.query(models.ProjectBatchStudent).filter(models.ProjectBatchStudent.student_id == current_user.user_id).first()
    if not link:
        return None # Return null if not in a batch
    
    batch = db.query(models.ProjectBatch).filter(models.ProjectBatch.id == link.batch_id).first()
    
    # Manually build response to include all details
    st_resp = []
    for bs in batch.students:
        st_resp.append(schemas.ProjectBatchStudentResponse(
            student_id=bs.student.user_id,
            name=bs.student.name,
            reg_no=bs.student.reg_no,
            email=bs.student.email,
            phone=bs.student.phone
        ) if bs.student else None)
    
    # Filter out None students if any (shouldn't happen with good data)
    st_resp = [s for s in st_resp if s]

    # Convert to response schema
    return schemas.ProjectBatchResponse(
        id=batch.id,
        guide_id=batch.guide.user_id,
        guide_name=batch.guide.name,
        reviewer_id=batch.reviewer_id,
        reviewer_name=batch.reviewer.name if batch.reviewer else None,
        reviewer_2_id=batch.reviewer_2_id,
        reviewer_2_name=batch.reviewer_2.name if batch.reviewer_2 else None,
        dept=batch.dept,
        year=batch.year,
        section=batch.section,
        project_title=batch.project_title,
        description=batch.description,
        zeroth_review_status=batch.zeroth_review_status,
        coordinator_remarks=batch.coordinator_remarks,
        start_date=batch.start_date,
        completion_status=batch.completion_status,
        final_demo_url=batch.final_demo_url,
        final_report_url=batch.final_report_url,
        students=st_resp,
        reviews=[schemas.ProjectReviewResponse(
            id=r.id,
            batch_id=r.batch_id,
            reviewer_id=r.reviewer_id,
            reviewer_name=r.reviewer.name if r.reviewer else None,
            review_number=r.review_number,
            feedback=r.feedback,
            reviewed_at=r.reviewed_at,
            student_marks=[schemas.ProjectStudentMarkResponse(
                student_id=m.student_id,
                student_name=m.student.name if m.student else None,
                marks=m.marks,
                feedback=m.feedback,
                id=m.id
            ) for m in r.student_marks]
        ) for r in batch.reviews],
        tasks=[schemas.ProjectTaskResponse.from_orm(t) for t in batch.tasks],
        base_papers=[schemas.ProjectBasePaperResponse.from_orm(bp) for bp in batch.base_papers],
        ppts=[schemas.ProjectPPTResponse.from_orm(p) for p in batch.ppts],
        created_at=batch.created_at
    )

@router.put("/batches/{batch_id}/reviewer", response_model=schemas.ProjectBatchResponse)
async def assign_batch_reviewer(
    batch_id: int,
    update: schemas.ProjectBatchReviewerUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Allow Project Coordinator to assign a reviewer to a batch.
    """
    batch = db.query(models.ProjectBatch).filter(models.ProjectBatch.id == batch_id).first()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")
    
    # Check if current_user is the coordinator for this batch's dept/year
    coord = db.query(models.ProjectCoordinator).filter(
        models.ProjectCoordinator.faculty_id == current_user.user_id,
        models.ProjectCoordinator.dept == batch.dept,
        models.ProjectCoordinator.year == batch.year
    ).first()
    
    if not coord:
        raise HTTPException(status_code=403, detail="Only the Project Coordinator for this department/year can assign reviewers")
    
    # Verify reviewer exists and is faculty
    reviewer = db.query(models.User).filter(
        models.User.user_id == update.reviewer_id,
        models.User.role == models.RoleEnum.FACULTY
    ).first()
    if not reviewer:
        raise HTTPException(status_code=404, detail="Reviewer not found or is not faculty")
    
    batch.reviewer_id = update.reviewer_id
    db.commit()
    db.refresh(batch)
    
    # Standard response build (can be refactored to helper if needed)
    st_resp = []
    for bs in batch.students:
        st_resp.append(schemas.ProjectBatchStudentResponse(
            student_id=bs.student.user_id,
            name=bs.student.name,
            reg_no=bs.student.reg_no,
            email=bs.student.email,
            phone=bs.student.phone
        ) if bs.student else None)
    st_resp = [s for s in st_resp if s]

    return schemas.ProjectBatchResponse(
        id=batch.id,
        guide_id=batch.guide.user_id,
        guide_name=batch.guide.name,
        reviewer_id=batch.reviewer_id,
        reviewer_name=reviewer.name,
        dept=batch.dept,
        year=batch.year,
        section=batch.section,
        students=st_resp,
        reviews=[schemas.ProjectReviewResponse(
            id=r.id,
            batch_id=r.batch_id,
            reviewer_id=r.reviewer_id,
            reviewer_name=r.reviewer.name if r.reviewer else None,
            review_number=r.review_number,
            marks=r.marks,
            feedback=r.feedback,
            reviewed_at=r.reviewed_at
        ) for r in batch.reviews],
        tasks=[schemas.ProjectTaskResponse.from_orm(t) for t in batch.tasks],
        created_at=batch.created_at
    )


@router.post("/reviews", response_model=schemas.ProjectReviewResponse)
async def create_project_review(
    review: schemas.ProjectReviewCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role([models.RoleEnum.HOD, models.RoleEnum.FACULTY]))
):
    """
    Allow Reviewers or Project Coordinator to record a project review with per-student marks.
    """
    # Verify batch exists
    batch = db.query(models.ProjectBatch).filter(models.ProjectBatch.id == review.batch_id).first()
    if not batch:
        raise HTTPException(status_code=404, detail="Project batch not found")
    
    # Check if user is the assigned reviewer (either 1 or 2)
    is_reviewer = (batch.reviewer_id == current_user.user_id) or (batch.reviewer_2_id == current_user.user_id)
    
    # Check if user is the coordinator
    coord = db.query(models.ProjectCoordinator).filter(
        models.ProjectCoordinator.faculty_id == current_user.user_id,
        models.ProjectCoordinator.dept == batch.dept,
        models.ProjectCoordinator.year == batch.year
    ).first()
    is_coordinator = coord is not None
    
    if not (is_reviewer or is_coordinator):
        raise HTTPException(status_code=403, detail="Only the assigned Reviewers or Project Coordinator can provide marks/feedback")

    # Check if review already exists for this number and this reviewer
    existing = db.query(models.ProjectReview).filter(
        models.ProjectReview.batch_id == review.batch_id,
        models.ProjectReview.review_number == review.review_number,
        models.ProjectReview.reviewer_id == current_user.user_id
    ).first()
    
    if existing:
        # Update existing review header
        existing.feedback = review.feedback
        existing.reviewed_at = models.datetime.utcnow()
        # Update student marks
        for m_schema in review.student_marks:
            existing_mark = db.query(models.ProjectStudentMark).filter(
                models.ProjectStudentMark.review_id == existing.id,
                models.ProjectStudentMark.student_id == m_schema.student_id
            ).first()
            if existing_mark:
                existing_mark.marks = m_schema.marks
                existing_mark.feedback = m_schema.feedback
            else:
                new_mark = models.ProjectStudentMark(
                    review_id=existing.id,
                    student_id=m_schema.student_id,
                    marks=m_schema.marks,
                    feedback=m_schema.feedback
                )
                db.add(new_mark)
        db.commit()
        db.refresh(existing)
        return existing

    new_review = models.ProjectReview(
        batch_id=review.batch_id,
        reviewer_id=current_user.user_id,
        review_number=review.review_number,
        feedback=review.feedback
    )
    db.add(new_review)
    db.commit()
    db.refresh(new_review)
    
    # Add student marks
    for m_schema in review.student_marks:
        new_mark = models.ProjectStudentMark(
            review_id=new_review.id,
            student_id=m_schema.student_id,
            marks=m_schema.marks,
            feedback=m_schema.feedback
        )
        db.add(new_mark)
    db.commit()
    db.refresh(new_review)
    
    return new_review


@router.put("/tasks/{task_id}", response_model=schemas.ProjectTaskResponse)
async def update_project_task(
    task_id: int,
    task_update: schemas.ProjectTaskUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Allow students or faculty to mark tasks as completed.
    """
    db_task = db.query(models.ProjectTask).filter(models.ProjectTask.id == task_id).first()
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Authorization check: either student in the batch or the guide
    batch = db_task.batch
    is_authorized = False
    
    if current_user.role == models.RoleEnum.FACULTY and batch.guide_id == current_user.user_id:
        is_authorized = True
    elif current_user.role == models.RoleEnum.STUDENT:
        link = db.query(models.ProjectBatchStudent).filter(
            models.ProjectBatchStudent.batch_id == batch.id,
            models.ProjectBatchStudent.student_id == current_user.user_id
        ).first()
        if link:
            is_authorized = True
    elif current_user.role == models.RoleEnum.HOD:
        is_authorized = True

    if not is_authorized:
        raise HTTPException(status_code=403, detail="You are not authorized to update this task")

    db_task.is_completed = task_update.is_completed
    db.commit()
    db.refresh(db_task)
    return db_task

@router.get("/guide-batches", response_model=List[schemas.ProjectBatchResponse])
async def get_guide_batches(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get all project batches where the current user is recorded as the guide.
    """
    if current_user.role not in [models.RoleEnum.FACULTY, models.RoleEnum.HOD]:
        raise HTTPException(status_code=403, detail="Only faculty and HODs can access this endpoint")
        
    batches = db.query(models.ProjectBatch).filter(
        or_(
            models.ProjectBatch.guide_id == current_user.user_id,
            models.ProjectBatch.reviewer_id == current_user.user_id
        )
    ).all()
    
    resp = []
    for batch in batches:
        st_resp = []
        for bs in batch.students:
            st_resp.append(schemas.ProjectBatchStudentResponse(
                student_id=bs.student.user_id,
                name=bs.student.name,
                reg_no=bs.student.reg_no,
                email=bs.student.email,
                phone=bs.student.phone
            ) if bs.student else None)
        st_resp = [s for s in st_resp if s]
        
        resp.append(schemas.ProjectBatchResponse(
            id=batch.id,
            guide_id=batch.guide.user_id,
            guide_name=batch.guide.name,
            reviewer_id=batch.reviewer_id,
            reviewer_name=batch.reviewer.name if batch.reviewer else None,
            dept=batch.dept,
            year=batch.year,
            section=batch.section,
            students=st_resp,
            reviews=[schemas.ProjectReviewResponse(
                id=r.id,
                batch_id=r.batch_id,
                reviewer_id=r.reviewer_id,
                reviewer_name=r.reviewer.name if r.reviewer else None,
                review_number=r.review_number,
                marks=r.marks,
                feedback=r.feedback,
                reviewed_at=r.reviewed_at
            ) for r in batch.reviews],
            tasks=[schemas.ProjectTaskResponse.from_orm(t) for t in batch.tasks],
            created_at=batch.created_at
        ))
    return resp

@router.get("/coordinator-batches", response_model=List[schemas.ProjectBatchResponse])
async def get_coordinator_batches(
    section: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get all project batches managed by the current user as Project Coordinator.
    """
    # Find all depts/years where user is coordinator
    coord_roles = db.query(models.ProjectCoordinator).filter(
        models.ProjectCoordinator.faculty_id == current_user.user_id
    ).all()
    
    if not coord_roles:
        return []
    
    # Collect batches for each dept/year
    all_batches = []
    for role in coord_roles:
        query = db.query(models.ProjectBatch).filter(
            models.ProjectBatch.dept == role.dept,
            models.ProjectBatch.year == role.year
        )
        if section:
            query = query.filter(models.ProjectBatch.section == section)
        
        batches = query.all()
        all_batches.extend(batches)
    
    resp = []
    for batch in all_batches:
        st_resp = []
        for bs in batch.students:
            st_resp.append(schemas.ProjectBatchStudentResponse(
                student_id=bs.student.user_id,
                name=bs.student.name,
                reg_no=bs.student.reg_no,
                email=bs.student.email,
                phone=bs.student.phone
            ) if bs.student else None)
        st_resp = [s for s in st_resp if s]
        
        resp.append(schemas.ProjectBatchResponse(
            id=batch.id,
            guide_id=batch.guide.user_id,
            guide_name=batch.guide.name,
            reviewer_id=batch.reviewer_id,
            reviewer_name=batch.reviewer.name if batch.reviewer else None,
            dept=batch.dept,
            year=batch.year,
            section=batch.section,
            students=st_resp,
            reviews=[schemas.ProjectReviewResponse(
                id=r.id,
                batch_id=r.batch_id,
                reviewer_id=r.reviewer_id,
                reviewer_name=r.reviewer.name if r.reviewer else None,
                review_number=r.review_number,
                marks=r.marks,
                feedback=r.feedback,
                reviewed_at=r.reviewed_at
            ) for r in batch.reviews],
            tasks=[schemas.ProjectTaskResponse.from_orm(t) for t in batch.tasks],
            created_at=batch.created_at
        ))
    return resp

@router.get("/reviewer-batches", response_model=List[schemas.ProjectBatchResponse])
async def get_reviewer_batches(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """
    Get all project batches where the current user is assigned as Reviewer.
    """
    batches = db.query(models.ProjectBatch).filter(models.ProjectBatch.reviewer_id == current_user.user_id).all()
    
    resp = []
    for batch in batches:
        st_resp = []
        for bs in batch.students:
            st_resp.append(schemas.ProjectBatchStudentResponse(
                student_id=bs.student.user_id,
                name=bs.student.name,
                reg_no=bs.student.reg_no,
                email=bs.student.email,
                phone=bs.student.phone
            ) if bs.student else None)
        st_resp = [s for s in st_resp if s]
        
        resp.append(schemas.ProjectBatchResponse(
            id=batch.id,
            guide_id=batch.guide.user_id,
            guide_name=batch.guide.name,
            reviewer_id=batch.reviewer_id,
            reviewer_name=current_user.name,
            dept=batch.dept,
            year=batch.year,
            section=batch.section,
            students=st_resp,
            reviews=[schemas.ProjectReviewResponse(
                id=r.id,
                batch_id=r.batch_id,
                reviewer_id=r.reviewer_id,
                reviewer_name=r.reviewer.name if r.reviewer else None,
                review_number=r.review_number,
                marks=r.marks,
                feedback=r.feedback,
                reviewed_at=r.reviewed_at
            ) for r in batch.reviews],
            tasks=[schemas.ProjectTaskResponse.from_orm(t) for t in batch.tasks],
            created_at=batch.created_at
        ))
    return resp

@router.put("/batches/{batch_id}", response_model=schemas.ProjectBatchResponse)
async def update_project_batch(
    batch_id: int,
    batch_update: schemas.ProjectBatchUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    """Update project metadata like title, description, zeroth review status etc."""
    batch = db.query(models.ProjectBatch).filter(models.ProjectBatch.id == batch_id).first()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")
    
    # Authorization: Coordinator can update anything, Guide can update title/desc
    coord = db.query(models.ProjectCoordinator).filter(
        models.ProjectCoordinator.faculty_id == current_user.user_id,
        models.ProjectCoordinator.dept == batch.dept,
        models.ProjectCoordinator.year == batch.year
    ).first()
    is_coord = coord is not None
    is_guide = batch.guide_id == current_user.user_id

    if not (is_coord or is_guide):
        raise HTTPException(status_code=403, detail="Unauthorized")

    if batch_update.project_title is not None:
        if batch.zeroth_review_status == "Approved" and not is_coord:
            raise HTTPException(status_code=403, detail="Topic locked after approval")
        batch.project_title = batch_update.project_title
    
    if batch_update.description is not None: batch.description = batch_update.description
    if batch_update.zeroth_review_status is not None and is_coord: 
        batch.zeroth_review_status = batch_update.zeroth_review_status
    if batch_update.coordinator_remarks is not None and is_coord:
        batch.coordinator_remarks = batch_update.coordinator_remarks
    if batch_update.start_date is not None: batch.start_date = batch_update.start_date
    if batch_update.completion_status is not None: batch.completion_status = batch_update.completion_status
    if batch_update.final_demo_url is not None: batch.final_demo_url = batch_update.final_demo_url
    if batch_update.final_report_url is not None: batch.final_report_url = batch_update.final_report_url

    db.commit()
    db.refresh(batch)
    return await get_my_project_batch(db, batch.students[0].student)

@router.post("/batches/{batch_id}/papers", response_model=schemas.ProjectBasePaperResponse)
async def submit_base_paper(
    batch_id: int,
    paper: schemas.ProjectBasePaperCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    # Verify student is in this batch
    link = db.query(models.ProjectBatchStudent).filter(
        models.ProjectBatchStudent.batch_id == batch_id,
        models.ProjectBatchStudent.student_id == current_user.user_id
    ).first()
    if not link:
        raise HTTPException(status_code=403, detail="Not in this batch")
    
    # Check limit of 3
    count = db.query(models.ProjectBasePaper).filter(models.ProjectBasePaper.batch_id == batch_id).count()
    if count >= 3:
        raise HTTPException(status_code=400, detail="Maximum 3 base papers allowed")
        
    new_paper = models.ProjectBasePaper(
        batch_id=batch_id,
        title=paper.title,
        file_url=paper.file_url
    )
    db.add(new_paper)
    db.commit()
    db.refresh(new_paper)
    return new_paper

@router.put("/papers/{paper_id}/select", response_model=schemas.ProjectBasePaperResponse)
async def select_base_paper(
    paper_id: int,
    feedback: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    paper = db.query(models.ProjectBasePaper).filter(models.ProjectBasePaper.id == paper_id).first()
    if not paper or paper.batch.guide_id != current_user.user_id:
        raise HTTPException(status_code=403, detail="Only the guide can select the paper")
    
    # Unselect others
    db.query(models.ProjectBasePaper).filter(models.ProjectBasePaper.batch_id == paper.batch_id).update({"is_selected": 0})
    
    paper.is_selected = 1
    if feedback: paper.guide_feedback = feedback
    db.commit()
    db.refresh(paper)
    return paper

@router.post("/batches/{batch_id}/ppts", response_model=schemas.ProjectPPTResponse)
async def upload_review_ppt(
    batch_id: int,
    ppt: schemas.ProjectPPTCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    # Verify student is in this batch
    link = db.query(models.ProjectBatchStudent).filter(
        models.ProjectBatchStudent.batch_id == batch_id,
        models.ProjectBatchStudent.student_id == current_user.user_id
    ).first()
    if not link: raise HTTPException(status_code=403, detail="Not in this batch")
    
    new_ppt = models.ProjectPPT(
        batch_id=batch_id,
        review_number=ppt.review_number,
        file_url=ppt.file_url
    )
    db.add(new_ppt)
    db.commit()
    db.refresh(new_ppt)
    return new_ppt

@router.put("/ppts/{ppt_id}/approve", response_model=schemas.ProjectPPTResponse)
async def approve_review_ppt(
    ppt_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    ppt = db.query(models.ProjectPPT).filter(models.ProjectPPT.id == ppt_id).first()
    if not ppt or ppt.batch.guide_id != current_user.user_id:
        raise HTTPException(status_code=403, detail="Only the guide can approve the PPT")
    
    ppt.guide_approved = 1
    db.commit()
    db.refresh(ppt)
    return ppt
