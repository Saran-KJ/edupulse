from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from database import get_db
import models
from models import (
    User, LearningResource, StudentBase, StudentCSE, StudentECE, StudentEEE,
    StudentMECH, StudentCIVIL, StudentBIO, StudentAIDS, StudentLearningProgress,
    PersonalizedLearningPlan, Mark, Subject
)
from auth import get_current_user
from ml_service import ml_service
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime
import schemas
import json

router = APIRouter()




# Assessment detection order: latest first
ASSESSMENT_FIELDS = [
    ("university_exam", "university_result_grade"),
    ("model", "model"),
    ("cia_2", "cia_2"),
    ("slip_test_4", "slip_test_4"),
    ("slip_test_3", "slip_test_3"),
    ("cia_1", "cia_1"),
    ("slip_test_2", "slip_test_2"),
    ("slip_test_1", "slip_test_1"),
]

STUDENT_MODEL_MAP = {
    'CSE': StudentCSE, 'ECE': StudentECE, 'EEE': StudentEEE,
    'MECH': StudentMECH, 'CIVIL': StudentCIVIL, 'BIO': StudentBIO, 'AIDS': StudentAIDS,
}

AVAILABLE_SKILLS = ["Communication", "Programming", "Aptitude", "Critical Thinking", "Leadership"]

# Learning type to resource type mapping (rule-based)
LEARNING_TYPE_MAP = {
    "video_tamil": {"types": ["video"], "language": "Tamil"},
    "pdf": {"types": ["article", "pdf"], "language": None},
    "visual": {"types": ["video", "image", "diagram"], "language": None},
    "text": {"types": ["article", "course"], "language": None},
}


def _get_student(db: Session, current_user: User):
    """Helper to retrieve student record from department table."""
    student_model = STUDENT_MODEL_MAP.get(current_user.dept)
    if not student_model:
        raise HTTPException(status_code=404, detail="Student department not found")
    student = db.query(student_model).filter(student_model.email == current_user.email).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")
    return student


def _get_student_by_reg(db: Session, reg_no: str, dept: str):
    """Helper to retrieve student record by reg_no and dept."""
    student_model = STUDENT_MODEL_MAP.get(dept)
    if not student_model:
        return None
    return db.query(student_model).filter(student_model.reg_no == reg_no).first()


def detect_latest_assessment(mark: Mark) -> str:
    """Detect which assessment was most recently entered (non-zero) for a mark record."""
    for assessment_key, field_name in ASSESSMENT_FIELDS:
        if field_name == "university_result_grade":
            val = getattr(mark, field_name, None)
            if val and val.strip():
                return assessment_key
        else:
            val = float(getattr(mark, field_name, 0) or 0)
            if val > 0:
                return assessment_key
    return "slip_test_1"  # default fallback


def _generate_practice_schedule(risk_level: str, subject_code: str, units: str) -> str:
    """
    Rule-based: Generate practice schedule based on risk level.
    High risk → daily structured plan
    Medium risk → weekly improvement targets
    Low risk → None (self-paced)
    """
    unit_list = units.split(",") if units else ["1"]
    
    if risk_level == "High":
        # Daily structured plan for high-risk subjects
        daily_plan = {
            "type": "daily",
            "subject": subject_code,
            "schedule": [
                {"day": "Monday", "task": f"Review Unit {unit_list[0]} basics (30 min)", "type": "revision"},
                {"day": "Tuesday", "task": f"Practice problems from Unit {unit_list[0]} (45 min)", "type": "practice"},
                {"day": "Wednesday", "task": f"Watch Tamil video explanations (30 min)", "type": "video"},
                {"day": "Thursday", "task": f"Solve quiz questions (30 min)", "type": "quiz"},
                {"day": "Friday", "task": f"Review weak areas & formula sheet (30 min)", "type": "revision"},
                {"day": "Saturday", "task": f"Full unit practice test (45 min)", "type": "test"},
                {"day": "Sunday", "task": "Rest / light revision of notes (15 min)", "type": "rest"},
            ],
            "daily_target_minutes": 30,
            "focus": "Build strong fundamentals with daily small steps"
        }
        return json.dumps(daily_plan)
    
    elif risk_level == "Medium":
        # Weekly improvement targets for medium-risk subjects
        weekly_plan = {
            "type": "weekly",
            "subject": subject_code,
            "schedule": [
                {"week": 1, "task": f"Complete revision of Units {','.join(unit_list[:2])}", "type": "revision"},
                {"week": 2, "task": "Solve practice questions (minimum 20)", "type": "practice"},
                {"week": 3, "task": "Attempt mock test and analyze mistakes", "type": "test"},
                {"week": 4, "task": "Focus on weak areas identified in mock test", "type": "targeted"},
            ],
            "weekly_target_hours": 3,
            "focus": "Consistent improvement through structured weekly goals"
        }
        return json.dumps(weekly_plan)
    
    return None


def _generate_weekly_goals(risk_level: str, subject_code: str) -> str:
    """Rule-based: Generate weekly goals based on risk level."""
    if risk_level == "High":
        goals = {
            "goals": [
                {"goal": "Complete at least 2 basic concept videos", "target": 2, "unit": "videos"},
                {"goal": "Solve 10 practice questions", "target": 10, "unit": "questions"},
                {"goal": "Review and memorize key formulas", "target": 1, "unit": "formula_sheet"},
                {"goal": "Take 1 self-assessment quiz", "target": 1, "unit": "quiz"},
            ],
            "priority": "high",
            "estimated_hours": 5
        }
        return json.dumps(goals)
    
    elif risk_level == "Medium":
        goals = {
            "goals": [
                {"goal": "Complete revision materials", "target": 3, "unit": "resources"},
                {"goal": "Solve 15 practice questions", "target": 15, "unit": "questions"},
                {"goal": "Track progress weekly", "target": 1, "unit": "progress_check"},
            ],
            "priority": "medium",
            "estimated_hours": 3
        }
        return json.dumps(goals)
    
    elif risk_level == "Low":
        goals = {
            "goals": [
                {"goal": "Explore advanced topics", "target": 2, "unit": "resources"},
                {"goal": "Complete enrichment activities", "target": 1, "unit": "activity"},
            ],
            "priority": "low",
            "estimated_hours": 2
        }
        return json.dumps(goals)
    
    return None


def generate_plan_for_subject(db: Session, reg_no: str, subject_code: str) -> Optional[PersonalizedLearningPlan]:
    """
    Generate or update a personalized learning plan for a student+subject.
    Called when marks are published or risk level changes.
    Uses ML for risk prediction, rule-based logic for plan generation.
    """
    # Get the mark record
    mark = db.query(Mark).filter(
        Mark.reg_no == reg_no,
        Mark.subject_code == subject_code
    ).first()
    if not mark:
        return None

    # Determine latest assessment
    latest_assessment = detect_latest_assessment(mark)
    
    # Fetch mapped units from DB instead of hardcoded dictionary
    assessment_mapping = db.query(models.AssessmentUnitMapping).filter(
        models.AssessmentUnitMapping.assessment_name == latest_assessment
    ).first()
    
    mapped_units = assessment_mapping.units.split(",") if assessment_mapping else ["1"]

    # Get subject risk level (ML-based Log Regression)
    subject_risk = ml_service.calculate_subject_risk(db, reg_no, subject_code)
    risk_level = subject_risk.get('risk_level', 'Low')
    if risk_level == 'Unknown':
        risk_level = 'Low'

    units_str = ",".join(mapped_units)

    # Rule-based: Determine focus type and resource level based on risk
    if risk_level == "High":
        focus_type = "Academic Recovery"
        resource_level = "Basic"
    elif risk_level == "Medium":
        focus_type = "Academic Improvement"
        resource_level = "Intermediate"
    else:
        # LOW risk: check if there's an existing active plan with a choice
        existing_plan = db.query(PersonalizedLearningPlan).filter(
            PersonalizedLearningPlan.reg_no == reg_no,
            PersonalizedLearningPlan.subject_code == subject_code,
            PersonalizedLearningPlan.is_active == 1,
            PersonalizedLearningPlan.risk_level == "Low"
        ).first()

        if existing_plan and existing_plan.focus_type in ["Academic Enhancement", "Skill Development"]:
            # Preserve the student's existing choice
            existing_plan.units = units_str
            existing_plan.latest_assessment = latest_assessment
            existing_plan.practice_schedule = _generate_practice_schedule(risk_level, subject_code, units_str)
            existing_plan.weekly_goals = _generate_weekly_goals(risk_level, subject_code)
            db.commit()
            db.refresh(existing_plan)
            return existing_plan
        else:
            # No choice made yet — mark as pending
            focus_type = "Pending Choice"
            resource_level = None

    # Rule-based: Generate practice schedule and weekly goals
    practice_schedule = _generate_practice_schedule(risk_level, subject_code, units_str)
    weekly_goals = _generate_weekly_goals(risk_level, subject_code)

    # Deactivate old plans for this student+subject
    db.query(PersonalizedLearningPlan).filter(
        PersonalizedLearningPlan.reg_no == reg_no,
        PersonalizedLearningPlan.subject_code == subject_code,
        PersonalizedLearningPlan.is_active == 1
    ).update({"is_active": 0})

    # Create new plan
    plan = PersonalizedLearningPlan(
        reg_no=reg_no,
        subject_code=subject_code,
        risk_level=risk_level,
        focus_type=focus_type,
        units=units_str,
        resource_level=resource_level,
        latest_assessment=latest_assessment,
        practice_schedule=practice_schedule,
        weekly_goals=weekly_goals,
        is_active=1
    )
    db.add(plan)
    db.commit()
    db.refresh(plan)
    return plan


def generate_plans_for_student(db: Session, reg_no: str):
    """Generate plans for ALL subjects of a student. Called on risk prediction."""
    marks = db.query(Mark).filter(Mark.reg_no == reg_no).all()
    subject_codes = set(m.subject_code for m in marks)
    for sc in subject_codes:
        try:
            generate_plan_for_subject(db, reg_no, sc)
        except Exception as e:
            print(f"Error generating plan for {reg_no}/{sc}: {e}")


# ─── API Endpoints ─────────────────────────────────────────────────────

@router.get("/plan/{subject_code}")
def get_personalized_plan(
    subject_code: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get the active personalized learning plan for a subject."""
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access plans")

    student = _get_student(db, current_user)

    # Check for existing active plan
    plan = db.query(PersonalizedLearningPlan).filter(
        PersonalizedLearningPlan.reg_no == student.reg_no,
        PersonalizedLearningPlan.subject_code == subject_code,
        PersonalizedLearningPlan.is_active == 1
    ).first()

    if not plan:
        # Auto-generate plan
        plan = generate_plan_for_subject(db, student.reg_no, subject_code)
        if not plan:
            raise HTTPException(status_code=404, detail="No marks data found for this subject")

    pending_choice = (plan.risk_level == "Low" and plan.focus_type == "Pending Choice")

    return {
        "id": plan.id,
        "reg_no": plan.reg_no,
        "subject_code": plan.subject_code,
        "risk_level": plan.risk_level,
        "focus_type": plan.focus_type,
        "units": plan.units,
        "skill_category": plan.skill_category,
        "resource_level": plan.resource_level,
        "latest_assessment": plan.latest_assessment,
        "practice_schedule": plan.practice_schedule,
        "weekly_goals": plan.weekly_goals,
        "is_active": plan.is_active,
        "created_at": plan.created_at.isoformat() if plan.created_at else None,
        "pending_choice": pending_choice,
        "available_skills": AVAILABLE_SKILLS if pending_choice else None,
    }


@router.post("/low-risk-choice")
def submit_low_risk_choice(
    request: schemas.LowRiskChoiceRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """LOW-risk student selects Academic Enhancement or Skill Development."""
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can make choices")

    student = _get_student(db, current_user)

    plan = db.query(PersonalizedLearningPlan).filter(
        PersonalizedLearningPlan.reg_no == student.reg_no,
        PersonalizedLearningPlan.subject_code == request.subject_code,
        PersonalizedLearningPlan.is_active == 1
    ).first()

    if not plan:
        raise HTTPException(status_code=404, detail="No active plan found")
    if plan.risk_level != "Low":
        raise HTTPException(status_code=400, detail="Choice is only available for LOW risk students")

    if request.choice == "academic_enhancement":
        plan.focus_type = "Academic Enhancement"
        plan.resource_level = "Advanced"
        plan.skill_category = None
    elif request.choice == "skill_development":
        plan.focus_type = "Skill Development"
        plan.resource_level = None
        plan.skill_category = None  # Will be set by skill-selection endpoint
    else:
        raise HTTPException(status_code=400, detail="Invalid choice. Use 'academic_enhancement' or 'skill_development'")

    # Generate practice and goals for low risk
    plan.practice_schedule = _generate_practice_schedule("Low", request.subject_code, plan.units or "1")
    plan.weekly_goals = _generate_weekly_goals("Low", request.subject_code)

    db.commit()
    db.refresh(plan)

    needs_skill_selection = (request.choice == "skill_development")

    return {
        "status": "success",
        "plan_id": plan.id,
        "focus_type": plan.focus_type,
        "needs_skill_selection": needs_skill_selection,
        "available_skills": AVAILABLE_SKILLS if needs_skill_selection else None,
    }


@router.post("/skill-selection")
def submit_skill_selection(
    request: schemas.SkillSelectionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """LOW-risk Skill Development student selects a specific skill."""
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can select skills")

    student = _get_student(db, current_user)

    plan = db.query(PersonalizedLearningPlan).filter(
        PersonalizedLearningPlan.reg_no == student.reg_no,
        PersonalizedLearningPlan.subject_code == request.subject_code,
        PersonalizedLearningPlan.is_active == 1,
        PersonalizedLearningPlan.focus_type == "Skill Development"
    ).first()

    if not plan:
        raise HTTPException(status_code=404, detail="No active Skill Development plan found")

    if request.skill not in AVAILABLE_SKILLS:
        raise HTTPException(status_code=400, detail=f"Invalid skill. Choose from: {AVAILABLE_SKILLS}")

    plan.skill_category = request.skill
    db.commit()
    db.refresh(plan)

    return {
        "status": "success",
        "plan_id": plan.id,
        "skill_category": plan.skill_category,
    }


@router.get("/plan/resources/{subject_code}")
def get_plan_resources(
    subject_code: str,
    language: str = "English",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get resources assigned by the active personalized learning plan.
    Rule-based resource selection using plan risk level and student preferences."""
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access resources")

    student = _get_student(db, current_user)

    # Get active plan
    plan = db.query(PersonalizedLearningPlan).filter(
        PersonalizedLearningPlan.reg_no == student.reg_no,
        PersonalizedLearningPlan.subject_code == subject_code,
        PersonalizedLearningPlan.is_active == 1
    ).first()

    if not plan:
        # Auto-generate
        plan = generate_plan_for_subject(db, student.reg_no, subject_code)
        if not plan:
            return {"plan": None, "resources": [], "progress": {"total": 0, "completed": 0, "percentage": 0}}

    if plan.focus_type == "Pending Choice":
        return {
            "plan": {
                "risk_level": plan.risk_level,
                "focus_type": plan.focus_type,
                "units": plan.units,
                "pending_choice": True,
                "available_skills": AVAILABLE_SKILLS,
                "practice_schedule": None,
                "weekly_goals": None,
            },
            "resources": [],
            "progress": {"total": 0, "completed": 0, "percentage": 0}
        }

    # Get completed resource IDs for this student
    completed_records = db.query(StudentLearningProgress).filter(
        StudentLearningProgress.reg_no == student.reg_no,
        StudentLearningProgress.completed == 1
    ).all()
    completed_ids = {r.resource_id for r in completed_records}

    # Rule-based: Get preferred learning type for filtering
    preferred_type = getattr(student, 'preferred_learning_type', 'text') or 'text'
    type_config = LEARNING_TYPE_MAP.get(preferred_type, {})
    preferred_res_types = type_config.get("types", [])
    forced_language = type_config.get("language", None)

    # Use forced language if learning type dictates it (e.g., video_tamil → Tamil)
    effective_language = forced_language if forced_language else language

    # Build resource query
    query = db.query(LearningResource)

    # Filter by department or general
    query = query.filter(
        (LearningResource.dept == current_user.dept) | (LearningResource.dept == None)
    )

    # Filter by language
    if effective_language and effective_language != "All":
        query = query.filter(LearningResource.language == effective_language)

    if plan.focus_type == "Skill Development" and plan.skill_category:
        # Skill-based resources
        query = query.filter(LearningResource.skill_category == plan.skill_category)
    else:
        # Academic resources — filter by resource level and units
        if plan.resource_level:
            query = query.filter(LearningResource.resource_level == plan.resource_level)

    resources = query.all()

    # In-memory filtering for unit matching and learning type preference
    filtered_resources = []
    preferred_resources = []  # Resources matching preferred type
    other_resources = []      # Other relevant resources

    for res in resources:
        # Skip already-completed resources
        if res.resource_id in completed_ids:
            continue

        should_include = False

        if plan.focus_type == "Skill Development":
            should_include = True
        else:
            # Academic plan — check unit overlap
            if plan.units and res.unit:
                plan_units = set(plan.units.split(","))
                res_units = set(res.unit.split(","))
                if plan_units & res_units:
                    should_include = True
            elif not res.unit:
                res_tags = (res.tags or "").lower()
                if subject_code.lower() in res_tags or "general" in res_tags:
                    should_include = True

        if should_include:
            # Separate by learning type preference
            if preferred_res_types and res.type in preferred_res_types:
                preferred_resources.append(res)
            else:
                other_resources.append(res)

    # Preferred resources first, then others
    filtered_resources = preferred_resources + other_resources

    # Build response
    resource_list = []
    for res in filtered_resources:
        resource_list.append({
            "resource_id": res.resource_id,
            "title": res.title,
            "description": res.description,
            "url": res.url,
            "type": res.type,
            "tags": res.tags,
            "unit": res.unit,
            "resource_level": res.resource_level,
            "skill_category": res.skill_category,
            "language": res.language,
            "is_completed": res.resource_id in completed_ids,
            "is_preferred_type": bool(preferred_res_types and res.type in preferred_res_types),
        })

    # Progress
    all_plan_resources_count = len(resource_list) + len([r for r in resources if r.resource_id in completed_ids])
    completed_count = len([r for r in resources if r.resource_id in completed_ids])
    percentage = (completed_count / all_plan_resources_count * 100) if all_plan_resources_count > 0 else 0

    # Parse practice schedule and weekly goals
    practice_data = None
    goals_data = None
    try:
        if plan.practice_schedule:
            practice_data = json.loads(plan.practice_schedule)
        if plan.weekly_goals:
            goals_data = json.loads(plan.weekly_goals)
    except Exception:
        pass

    return {
        "plan": {
            "Risk Level": plan.risk_level,
            "Focus Type": plan.focus_type,
            "Unit(s) or Skill": plan.skill_category if plan.focus_type == "Skill Development" else plan.units,
            "Assigned Learning Resource(s)": resource_list,
            
            # Keep original fields for backward compatibility with frontend
            "id": plan.id,
            "risk_level": plan.risk_level,
            "focus_type": plan.focus_type,
            "units": plan.units,
            "skill_category": plan.skill_category,
            "resource_level": plan.resource_level,
            "latest_assessment": plan.latest_assessment,
            "pending_choice": False,
            "practice_schedule": practice_data,
            "weekly_goals": goals_data,
        },
        "resources": resource_list,
        "progress": {
            "total": all_plan_resources_count,
            "completed": completed_count,
            "percentage": round(percentage, 1)
        }
    }


# ─── Overall Learning View ──────────────────────────────────────────────

@router.get("/overall-view")
def get_overall_learning_view(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Aggregated overall personalized learning view.
    Combines all subject-wise risk levels and recommends:
    - Priority subjects for improvement
    - Overall study strategy
    - Balanced learning resources across subjects
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access learning views")

    student = _get_student(db, current_user)
    preferred_type = getattr(student, 'preferred_learning_type', 'text') or 'text'

    # Get all marks for this student
    marks = db.query(Mark).filter(Mark.reg_no == student.reg_no).all()
    if not marks:
        return {
            "overall_risk": "Unknown",
            "priority_subjects": [],
            "study_strategy": {"message": "No academic data available yet"},
            "total_progress": 0,
            "preferred_learning_type": preferred_type
        }

    # Get or generate plans for all subjects
    subject_statuses = []
    risk_counts = {"High": 0, "Medium": 0, "Low": 0}

    for mark in marks:
        # Check if subject is LAB to skip it from learning plans
        subject = db.query(models.Subject).filter(
            func.lower(models.Subject.subject_code) == mark.subject_code.lower()
        ).first()
        
        if subject and subject.category == 'LAB':
            continue

        # Get active plan
        plan = db.query(PersonalizedLearningPlan).filter(
            PersonalizedLearningPlan.reg_no == student.reg_no,
            PersonalizedLearningPlan.subject_code == mark.subject_code,
            PersonalizedLearningPlan.is_active == 1
        ).first()

        if not plan:
            plan = generate_plan_for_subject(db, student.reg_no, mark.subject_code)

        if plan:
            # Calculate progress for this subject
            completed_count = db.query(StudentLearningProgress).filter(
                StudentLearningProgress.reg_no == student.reg_no,
                StudentLearningProgress.completed == 1
            ).count()
            total_resources = db.query(LearningResource).filter(
                (LearningResource.dept == current_user.dept) | (LearningResource.dept == None),
                LearningResource.resource_level == plan.resource_level
            ).count()
            progress = (completed_count / total_resources * 100) if total_resources > 0 else 0

            risk_level = plan.risk_level if plan.risk_level in risk_counts else "Low"
            risk_counts[risk_level] = risk_counts.get(risk_level, 0) + 1

            subject_statuses.append({
                "subject_code": mark.subject_code,
                "subject_title": mark.subject_title,
                "risk_level": plan.risk_level,
                "focus_type": plan.focus_type,
                "progress_percentage": round(progress, 1),
                "practice_schedule": plan.practice_schedule,
                "weekly_goals": plan.weekly_goals,
            })

    # Sort by risk priority: High → Medium → Low
    risk_priority = {"High": 0, "Medium": 1, "Low": 2}
    subject_statuses.sort(key=lambda x: risk_priority.get(x["risk_level"], 3))

    # Determine overall risk
    if risk_counts["High"] > 0:
        overall_risk = "High"
    elif risk_counts["Medium"] > 0:
        overall_risk = "Medium"
    else:
        overall_risk = "Low"

    # Rule-based: Generate study strategy
    total_subjects = len(subject_statuses)
    high_subjects = [s for s in subject_statuses if s["risk_level"] == "High"]
    medium_subjects = [s for s in subject_statuses if s["risk_level"] == "Medium"]
    low_subjects = [s for s in subject_statuses if s["risk_level"] == "Low"]

    study_strategy = {
        "overall_risk": overall_risk,
        "total_subjects": total_subjects,
        "high_risk_count": len(high_subjects),
        "medium_risk_count": len(medium_subjects),
        "low_risk_count": len(low_subjects),
        "time_allocation": {},
        "recommendations": [],
    }

    # Time allocation ratios based on risk distribution
    if len(high_subjects) > 0:
        study_strategy["time_allocation"] = {
            "high_risk_subjects": "50% of study time",
            "medium_risk_subjects": "35% of study time",
            "low_risk_subjects": "15% of study time",
        }
        study_strategy["recommendations"].append(
            f"Focus primarily on {len(high_subjects)} high-risk subject(s): "
            + ", ".join([s['subject_title'] for s in high_subjects])
        )
        study_strategy["recommendations"].append(
            "Use daily practice plans for high-risk subjects"
        )
    elif len(medium_subjects) > 0:
        study_strategy["time_allocation"] = {
            "medium_risk_subjects": "60% of study time",
            "low_risk_subjects": "40% of study time",
        }
        study_strategy["recommendations"].append(
            f"Focus on improving {len(medium_subjects)} medium-risk subject(s): "
            + ", ".join([s['subject_title'] for s in medium_subjects])
        )
        study_strategy["recommendations"].append(
            "Follow weekly improvement plans for consistent progress"
        )
    else:
        study_strategy["time_allocation"] = {
            "all_subjects": "Equal time across subjects",
        }
        study_strategy["recommendations"].append(
            "Great performance! Focus on advanced topics and skill development"
        )

    study_strategy["recommendations"].append(
        f"Preferred learning style: {preferred_type.replace('_', ' ').title()}"
    )

    # Total progress
    total_progress = sum(s["progress_percentage"] for s in subject_statuses) / len(subject_statuses) if subject_statuses else 0

    return {
        "overall_risk": overall_risk,
        "priority_subjects": subject_statuses,
        "study_strategy": study_strategy,
        "total_progress": round(total_progress, 1),
        "preferred_learning_type": preferred_type
    }


# ─── Preferred Learning Type ────────────────────────────────────────────

@router.patch("/preferred-type")
def set_preferred_learning_type(
    request: schemas.PreferredLearningTypeRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Student sets their preferred learning type (video_tamil, pdf, visual, text)."""
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can set learning preferences")

    valid_types = ["video_tamil", "pdf", "visual", "text"]
    if request.learning_type not in valid_types:
        raise HTTPException(status_code=400, detail=f"Invalid type. Choose from: {valid_types}")

    student = _get_student(db, current_user)
    student.preferred_learning_type = request.learning_type
    db.commit()

    return {
        "status": "success",
        "preferred_learning_type": request.learning_type,
        "description": {
            "video_tamil": "Tamil video content prioritized",
            "pdf": "PDF notes and articles prioritized",
            "visual": "Visual content (images/diagrams/videos) prioritized",
            "text": "Simple textual explanations prioritized",
        }.get(request.learning_type, "")
    }


# ─── Class Advisor Monitoring ────────────────────────────────────────────

@router.get("/advisor/students/{dept}/{year}/{section}")
def get_advisor_student_progress(
    dept: str,
    year: int,
    section: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Class advisor view: monitor all students' learning progress."""
    if current_user.role not in ["class_advisor", "admin", "hod", "principal", "vice_principal"]:
        raise HTTPException(status_code=403, detail="Only advisors and admins can access this")

    student_model = STUDENT_MODEL_MAP.get(dept)
    if not student_model:
        raise HTTPException(status_code=404, detail="Department not found")

    students = db.query(student_model).filter(
        student_model.year == year,
        student_model.section == section
    ).all()

    result = []
    for student in students:
        # Get all plans for this student
        plans = db.query(PersonalizedLearningPlan).filter(
            PersonalizedLearningPlan.reg_no == student.reg_no,
            PersonalizedLearningPlan.is_active == 1
        ).all()

        high_count = sum(1 for p in plans if p.risk_level == "High")
        medium_count = sum(1 for p in plans if p.risk_level == "Medium")
        low_count = sum(1 for p in plans if p.risk_level == "Low")

        # Overall risk
        if high_count > 0:
            overall_risk = "High"
        elif medium_count > 0:
            overall_risk = "Medium"
        else:
            overall_risk = "Low"

        # Calculate overall progress
        completed = db.query(StudentLearningProgress).filter(
            StudentLearningProgress.reg_no == student.reg_no,
            StudentLearningProgress.completed == 1
        ).count()
        total = db.query(StudentLearningProgress).filter(
            StudentLearningProgress.reg_no == student.reg_no
        ).count()
        overall_progress = (completed / total * 100) if total > 0 else 0

        subjects = []
        for p in plans:
            mark = db.query(Mark).filter(
                Mark.reg_no == student.reg_no,
                Mark.subject_code == p.subject_code
            ).first()
            subjects.append({
                "subject_code": p.subject_code,
                "subject_title": mark.subject_title if mark else p.subject_code,
                "risk_level": p.risk_level,
                "focus_type": p.focus_type,
                "progress_percentage": 0,
                "practice_schedule": p.practice_schedule,
                "weekly_goals": p.weekly_goals,
            })

        result.append({
            "reg_no": student.reg_no,
            "student_name": student.name,
            "overall_risk": overall_risk,
            "high_risk_count": high_count,
            "medium_risk_count": medium_count,
            "low_risk_count": low_count,
            "overall_progress": round(overall_progress, 1),
            "subjects": subjects,
        })

    # Sort by risk severity (High risk students first)
    risk_order = {"High": 0, "Medium": 1, "Low": 2}
    result.sort(key=lambda x: risk_order.get(x["overall_risk"], 3))

    return {"students": result, "total": len(result)}


# ─── High-Risk Alerts ────────────────────────────────────────────────────

@router.get("/alerts")
def get_high_risk_alerts(
    dept: Optional[str] = None,
    year: Optional[int] = None,
    section: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get alerts for high-risk students. Accessible by advisors and admins."""
    if current_user.role not in ["class_advisor", "admin", "hod", "principal", "vice_principal", "faculty"]:
        raise HTTPException(status_code=403, detail="Not authorized to view alerts")

    # Get all active high-risk plans
    query = db.query(PersonalizedLearningPlan).filter(
        PersonalizedLearningPlan.is_active == 1,
        PersonalizedLearningPlan.risk_level == "High"
    )

    plans = query.all()

    # Group by student
    student_alerts = {}
    for plan in plans:
        if plan.reg_no not in student_alerts:
            student_alerts[plan.reg_no] = {
                "high_risk_subjects": [],
                "subject_titles": []
            }
        # Get subject title
        mark = db.query(Mark).filter(
            Mark.reg_no == plan.reg_no,
            Mark.subject_code == plan.subject_code
        ).first()
        student_alerts[plan.reg_no]["high_risk_subjects"].append(plan.subject_code)
        if mark:
            student_alerts[plan.reg_no]["subject_titles"].append(mark.subject_title)

    alerts = []
    for reg_no, data in student_alerts.items():
        # Find student details
        mark = db.query(Mark).filter(Mark.reg_no == reg_no).first()
        if not mark:
            continue

        # Filter by dept/year/section if provided
        if dept and mark.dept != dept:
            continue
        if year and mark.year != year:
            continue
        if section and mark.section != section:
            continue

        high_count = len(data["high_risk_subjects"])
        severity = "critical" if high_count >= 3 else "warning"

        # Rule-based recommended actions
        actions = []
        if high_count >= 3:
            actions.append("Schedule immediate one-on-one counseling session")
            actions.append("Contact parent/guardian for academic support meeting")
            actions.append("Assign peer mentor from low-risk students")
        else:
            actions.append("Monitor closely in upcoming assessments")
            actions.append("Ensure student is following daily practice plan")

        actions.append(f"Prioritize these subjects: {', '.join(data['subject_titles'])}")

        alerts.append({
            "reg_no": reg_no,
            "student_name": mark.student_name,
            "dept": mark.dept,
            "year": mark.year,
            "section": mark.section,
            "high_risk_subjects": data["subject_titles"],
            "alert_severity": severity,
            "recommended_actions": actions,
        })

    # Sort: critical first
    alerts.sort(key=lambda x: 0 if x["alert_severity"] == "critical" else 1)

    return {"alerts": alerts, "total": len(alerts)}


# ─── Legacy endpoint (kept for dashboard compatibility) ─────────────────

@router.get("/recommendations", response_model=Dict[str, Any])
def get_learning_recommendations(
    subject_code: Optional[str] = None,
    language: str = "English",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Legacy endpoint — now delegates to personalized plan resources if subject_code provided."""
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can get recommendations")

    student = _get_student(db, current_user)

    # Get risk prediction
    risk_level = 'Low'
    risk_basis = 'General'
    risk_score = 0

    if subject_code:
        subject_risk = ml_service.calculate_subject_risk(db, student.reg_no, subject_code)
        risk_level = subject_risk['risk_level']
        risk_score = subject_risk['score']
        risk_basis = f"Subject Risk: {risk_level} ({subject_risk['basis']})"
    else:
        risk_data = ml_service.predict_risk(db, student.reg_no)
        risk_level = risk_data.get('risk_level', 'Low')
        risk_basis = f"Overall Risk: {risk_level}"

        # Feature 3: Auto-map resources by current semester subjects
        semester_num = getattr(student, 'semester', None)
        if semester_num:
            roman_map = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V', 6: 'VI', 7: 'VII', 8: 'VIII'}
            roman_sem = roman_map.get(int(semester_num), None)
            if roman_sem:
                semester_subjects = db.query(Subject).filter(
                    Subject.semester == roman_sem
                ).all()
                # Collect subject codes for this semester to filter resources
                semester_codes = [s.subject_code.lower() for s in semester_subjects]

    # Query resources
    query = db.query(LearningResource)
    query = query.filter((LearningResource.dept == current_user.dept) | (LearningResource.dept == None))

    if language and language != "All":
        query = query.filter(LearningResource.language == language)

    resources = query.all()

    # Get completed resources
    completed_records = db.query(StudentLearningProgress).filter(
        StudentLearningProgress.reg_no == student.reg_no,
        StudentLearningProgress.completed == 1
    ).all()
    completed_ids = {record.resource_id for record in completed_records}

    filtered_resources = []
    for res in resources:
        res_tags = (res.tags or "").lower()
        should_include = True

        if res.min_risk_level:
            risk_map = {'Low': 1, 'Medium': 2, 'High': 3}
            student_risk_val = risk_map.get(risk_level, 1)
            res_risk_val = risk_map.get(res.min_risk_level, 1)
            if student_risk_val < res_risk_val:
                should_include = False

        if subject_code and should_include:
            if subject_code.lower() not in res_tags:
                should_include = False

        if should_include:
            res_dict = {
                "resource_id": res.resource_id,
                "title": res.title,
                "description": res.description,
                "url": res.url,
                "type": res.type,
                "tags": res.tags,
                "is_completed": res.resource_id in completed_ids
            }
            filtered_resources.append(res_dict)

    total_recommended = len(filtered_resources)
    total_completed = sum(1 for r in filtered_resources if r['is_completed'])
    progress_percentage = (total_completed / total_recommended * 100) if total_recommended > 0 else 0

    if risk_level == "High":
        filtered_resources.sort(key=lambda x: x['type'] != 'quiz')

    return {
        "resources": filtered_resources,
        "risk_context": {
            "level": risk_level,
            "basis": risk_basis,
            "score": risk_score
        },
        "progress": {
            "total": total_recommended,
            "completed": total_completed,
            "percentage": progress_percentage
        }
    }


class ProgressUpdate(BaseModel):
    resource_id: int
    completed: bool

@router.post("/progress")
def update_progress(
    update: ProgressUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Mark a resource as completed."""
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can update progress")

    student = _get_student(db, current_user)

    progress = db.query(StudentLearningProgress).filter(
        StudentLearningProgress.reg_no == student.reg_no,
        StudentLearningProgress.resource_id == update.resource_id
    ).first()

    if progress:
        progress.completed = 1 if update.completed else 0
        progress.completed_at = datetime.utcnow()
    else:
        progress = StudentLearningProgress(
            reg_no=student.reg_no,
            resource_id=update.resource_id,
            completed=1 if update.completed else 0
        )
        db.add(progress)

    db.commit()
    return {"status": "success"}
