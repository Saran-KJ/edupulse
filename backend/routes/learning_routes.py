from fastapi import APIRouter, Depends, HTTPException, Body, BackgroundTasks, Query
from sqlalchemy.orm import Session
from datetime import datetime
from sqlalchemy import func
from database import get_db, SessionLocal
import models
from models import (
    User, LearningResource, StudentBase, StudentCSE, StudentECE, StudentEEE,
    StudentMECH, StudentCIVIL, StudentBIO, StudentAIDS, StudentLearningProgress,
    PersonalizedLearningPlan, Mark, Subject, YouTubeRecommendation
)
from auth import get_current_user
from ml_service import ml_service
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime
import schemas
import json
import requests
import config as cfg
import gemini_service

settings = cfg.get_settings()

YOUTUBE_API_KEY = settings.youtube_api_key
YOUTUBE_SEARCH_URL = "https://www.googleapis.com/youtube/v3/search"

# For embedded video support, provide video watch URL and embed URL
WATCH_URL_BASE = "https://www.youtube.com/watch?v="
EMBED_URL_BASE = "https://www.youtube.com/embed/"

router = APIRouter()




# Assessment detection order: latest first
ASSESSMENT_FIELDS = [
    ("university_exam", "university_result_grade"),
    ("model", "model"),
    ("cia_2", "cia_2"),
    ("slip_test_4", "slip_test_4"),
    ("assignment_4", "assignment_4"),
    ("slip_test_3", "slip_test_3"),
    ("assignment_3", "assignment_3"),
    ("cia_1", "cia_1"),
    ("slip_test_2", "slip_test_2"),
    ("assignment_2", "assignment_2"),
    ("slip_test_1", "slip_test_1"),
    ("assignment_1", "assignment_1"),
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

    # Determine all published assessments and aggregate units
    published_assessments = []
    for assessment_key, field_name in ASSESSMENT_FIELDS:
        if field_name == "university_result_grade":
            val = getattr(mark, field_name, None)
            if val and val.strip():
                published_assessments.append(assessment_key)
        else:
            val = float(getattr(mark, field_name, 0) or 0)
            if val > 0:
                published_assessments.append(assessment_key)
    
    latest_assessment = published_assessments[0] if published_assessments else "slip_test_1"
    
    # Collect all unique units from all published assessments
    mapped_units_set = set()
    if not published_assessments:
        mapped_units_set.add("1")
    else:
        for assessment in published_assessments:
            mapping = db.query(models.AssessmentUnitMapping).filter(
                models.AssessmentUnitMapping.assessment_name == assessment
            ).first()
            if mapping:
                for u in mapping.units.split(","):
                    mapped_units_set.add(u.strip())
    
    if not mapped_units_set:
        mapped_units_set.add("1")
        
    mapped_units = sorted(list(mapped_units_set), key=lambda x: int(x) if x.isdigit() else 999)

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
        # LOW risk subject: check overall risk to see if they get a choice
        # Check db first
        today = datetime.utcnow().date()
        recent_prediction = db.query(models.RiskPrediction).filter(
            models.RiskPrediction.reg_no == reg_no,
        ).order_by(models.RiskPrediction.prediction_date.desc()).first()
        
        if recent_prediction and recent_prediction.prediction_date.date() == today:
            print(f"DEBUG: Using cached risk prediction for {reg_no} in global path")
            overall_risk_data = {
                'risk_level': recent_prediction.risk_level,
                'risk_score': recent_prediction.risk_score,
                'reasons': recent_prediction.reasons
            }
        else:
            print(f"DEBUG: Triggering live risk prediction for {reg_no} in global path")
            overall_risk_data = ml_service.predict_risk(db, reg_no)
            ml_service.save_prediction(db, reg_no, overall_risk_data)
        overall_risk = overall_risk_data.get('risk_level', 'Low')
        
        if overall_risk != "Low":
            # If OVERALL risk is not Low, force Academic Enhancement (no choice)
            focus_type = "Academic Enhancement"
            resource_level = "Advanced"
        else:
            # Overall risk is also LOW — respect global preference
            from models import User
            user = db.query(User).filter(models.User.reg_no == reg_no).first()
            student_pref = None
            if user:
                student_model = STUDENT_MODEL_MAP.get(user.dept)
                if student_model:
                    student = db.query(student_model).filter(student_model.reg_no == reg_no).first()
                    if student:
                        student_pref = student.learning_path_preference
            
            if student_pref:
                focus_type = student_pref
                resource_level = "Advanced" if focus_type == "Academic Enhancement" else "Intermediate"
            else:
                # No choice made yet — mark as pending
                focus_type = "Pending Choice"
                resource_level = None

    # Rule-based fallback: Generate practice schedule and weekly goals
    practice_schedule = _generate_practice_schedule(risk_level, subject_code, units_str)
    weekly_goals = _generate_weekly_goals(risk_level, subject_code)

    # Use Gemini only for Academic paths (not Skill Development)
    academic_paths = ["Academic Recovery", "Academic Improvement", "Academic Enhancement"]
    if focus_type in academic_paths:
        ai_schedule, ai_goals = gemini_service.generate_subject_plan(
            subject_code, risk_level, focus_type
        )
        if ai_schedule and ai_goals:
            practice_schedule = json.dumps(ai_schedule)
            weekly_goals = json.dumps(ai_goals)
    # Skill Development uses rule-based fallbacks (already set above)

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


def fetch_youtube_recommendations(
    db: Session, 
    reg_no: str, 
    subject_code: str, 
    subject_title: str,
    units: List[str], 
    risk_level: str, 
    language: str
) -> List[Dict[str, Any]]:
    """
    Fetch YouTube learning resources dynamically.
    Iterates through each unit to provide unit-specific results.
    """
    all_recommendations = []
    
    for single_unit in units:
        # 1. Check Cache (valid for 24 hours)
        cached = db.query(YouTubeRecommendation).filter(
            YouTubeRecommendation.reg_no == reg_no,
            YouTubeRecommendation.subject_code == subject_code,
            YouTubeRecommendation.unit == single_unit,
            YouTubeRecommendation.risk_level == risk_level,
            YouTubeRecommendation.language == language
        ).all()
        
        if cached:
            for c in cached:
                all_recommendations.append({
                    "resource_id": 1000000 + c.id,
                    "title": c.title,
                    "description": f"Recommended video for {subject_title} Unit {single_unit}",
                    "url": c.video_url,
                    "type": "video",
                    "tags": f"YouTube,Dynamic,{risk_level}",
                    "unit": c.unit,
                    "resource_level": risk_level,
                    "language": language,
                    "is_completed": False,
                    "is_dynamic": True
                })
            print(f"DEBUG: Found {len(cached)} cached YouTube recommendations for {subject_code} Unit {single_unit}")
            continue

        # 2. Build Query for this unit
        # Wrapping subject_title in quotes helps exact matching
        query = f'"{subject_title}" Unit {single_unit} engineering lecture university syllabus -experience -warning -shorts -vlog -update -notice -nptel_experience'
        
        if risk_level == "High":
            query += " basic concepts and introduction"
        elif risk_level == "Medium":
            query += " detailed explanation and examples"
        else:
            query += " advanced topics and applications"

        if language == "Tamil":
            query += " in Tamil"
        elif language == "English":
            query += " in English"

        # 3. Call YouTube API
        if not YOUTUBE_API_KEY:
            continue

        try:
            params = {
                "part": "snippet",
                "q": query,
                "key": YOUTUBE_API_KEY,
                "maxResults": 5, # Fetch more to allow filtering
                "type": "video",
                "videoEmbeddable": "true",
                "relevanceLanguage": "ta" if language == "Tamil" else "en"
            }
            print(f"DEBUG: Calling YouTube API for query: {query}")
            resp = requests.get(YOUTUBE_SEARCH_URL, params=params)
            resp.raise_for_status()
            data = resp.json()

            count_saved = 0
            for item in data.get("items", []):
                if count_saved >= 2: break # Limit to 2 filtered results per unit

                video_id = item["id"]["videoId"]
                title = item["snippet"]["title"]
                thumb = item["snippet"]["thumbnails"]["default"]["url"]
                video_url = f"https://www.youtube.com/watch?v={video_id}"

                # Post-fetch filtering to catch common irrelevant educational "meta" content
                title_lower = title.lower()
                irrelevant_keywords = ["don't watch", "warning", "notice", "update", "experience", "vlog", "shorts", "news", "wrong"]
                if any(kw in title_lower for kw in irrelevant_keywords):
                    print(f"DEBUG: Skipping irrelevant video: {title}")
                    continue

                # Save to Cache
                rec_entry = YouTubeRecommendation(
                    reg_no=reg_no,
                    subject_code=subject_code,
                    unit=single_unit,
                    video_id=video_id,
                    title=title,
                    thumbnail=thumb,
                    video_url=video_url,
                    risk_level=risk_level,
                    language=language
                )
                db.add(rec_entry)
                db.flush()
                count_saved += 1
                db.flush()
                
                all_recommendations.append({
                    "resource_id": 1000000 + (rec_entry.id or 0),
                    "title": title,
                    "description": f"Recommended video for {subject_title} Unit {single_unit}",
                    "url": video_url,
                    "type": "video",
                    "tags": f"YouTube,Dynamic,{risk_level}",
                    "unit": single_unit,
                    "resource_level": risk_level,
                    "language": language,
                    "is_completed": False,
                    "is_dynamic": True
                })
        except Exception as e:
            print(f"Error fetching YouTube results for unit {single_unit}: {e}")

    db.commit()
    return all_recommendations


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

    return {
        "status": "success",
        "plan_id": plan.id,
        "focus_type": plan.focus_type,
        "needs_skill_selection": False,  # Student can browse ALL skills freely
        "available_skills": None,
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


@router.post("/global-path")
def set_global_path_preference(
    request: schemas.GlobalPathPreferenceRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Set the global learning path preference for a Low-risk student."""
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can set preferences")

    # 1. Verify Overall Risk is LOW
    # Get Risk Level from DB instead of live calculation
    from datetime import datetime
    today = datetime.utcnow().date()
    recent_prediction = db.query(models.RiskPrediction).filter(
        models.RiskPrediction.reg_no == current_user.reg_no,
    ).order_by(models.RiskPrediction.prediction_date.desc()).first()
    
    if recent_prediction and recent_prediction.prediction_date.date() == today:
        print(f"DEBUG: Using cached risk prediction for {current_user.reg_no} in overall view")
        risk_data = {
            'risk_level': recent_prediction.risk_level,
            'risk_score': recent_prediction.risk_score
        }
    else:
        print(f"DEBUG: Triggering live risk prediction for {current_user.reg_no} in overall view")
        risk_data = ml_service.predict_risk(db, current_user.reg_no)
        ml_service.save_prediction(db, current_user.reg_no, risk_data)
    if risk_data.get('risk_level') != 'Low':
        raise HTTPException(status_code=400, detail="Only Overall Low-risk students can set a global preference.")
    
    # 2. Update Student Record and Clear Cache
    student = _get_student(db, current_user)
    student.learning_path_preference = request.choice
    student.learning_sub_preference = request.sub_choice
    student.overall_study_strategy = None  # Clear cache to force AI re-generation
    db.commit()
    
    # 3. Refresh subject plans in background (takes ~15-20s as it calls Gemini for each)
    background_tasks.add_task(generate_plans_for_student_task, current_user.reg_no)
    
    msg = f"Global preference set to {request.choice}"
    if request.sub_choice:
        msg += f" ({request.sub_choice})"
    
    return {"status": "success", "message": f"{msg}. Plans are being updated in the background."}

def generate_plans_for_student_task(reg_no: str):
    """Background task to generate plans for a student."""
    db = SessionLocal()
    try:
        generate_plans_for_student(db, reg_no)
    finally:
        db.close()


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
    else:
        # Check if plan risk is stale compared to live prediction
        current_risk_data = ml_service.calculate_subject_risk(db, student.reg_no, subject_code)
        current_risk = current_risk_data.get('risk_level', 'Low')
        
        if plan.risk_level != current_risk:
            print(f"DEBUG: Risk discrepancy detected for {subject_code} ({plan.risk_level} vs {current_risk}). Regenerating plan.")
            plan = generate_plan_for_subject(db, student.reg_no, subject_code)

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
    
    # Filter by subject
    if plan.focus_type != "Skill Development":
        query = query.filter(
            (LearningResource.subject_code == subject_code) | (LearningResource.subject_code == None)
        )

    # Filter by language
    if effective_language and effective_language != "All":
        query = query.filter(
            (LearningResource.language == effective_language) | 
            (LearningResource.language == "English")
        )

    if plan.focus_type == "Skill Development":
        # Return ALL skill resources — student can learn any skill freely
        query = query.filter(LearningResource.skill_category != None)
    else:
        # Academic resources — filter by resource level (cumulative: High=Basic, Medium=Basic+Inter, Low=all)
        if plan.resource_level:
            level_filter = {
                "Basic": ["Basic"],
                "Intermediate": ["Intermediate"],
                "Advanced": ["Advanced"],
            }
            allowed_levels = level_filter.get(plan.resource_level, [plan.resource_level])
            query = query.filter(
                (LearningResource.resource_level.in_(allowed_levels)) |
                (LearningResource.resource_level == None)
            )

    resources = query.all()

    # Dynamic YouTube Recommendations
    subject = db.query(models.Subject).filter(
        func.lower(models.Subject.subject_code) == subject_code.lower()
    ).first()
    subject_title = subject.subject_title if subject else subject_code
    
    plan_units = plan.units.split(",") if plan.units else ["1"]
    dynamic_videos = fetch_youtube_recommendations(
        db, 
        student.reg_no, 
        subject_code, 
        subject_title,
        plan_units, 
        plan.risk_level, 
        effective_language
    )

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
            # Academic plan
            if getattr(res, 'subject_code', None) not in (subject_code, None):
                continue
                
            # check unit overlap
            if plan.units and res.unit:
                plan_units = set(plan.units.split(","))
                res_units = set(res.unit.split(","))
                if plan_units & res_units:
                    should_include = True
            else:
                res_tags = (res.tags or "").lower()
                if getattr(res, 'subject_code', None) == subject_code or subject_code.lower() in res_tags or "general" in res_tags:
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
    
    # Add dynamic videos first (since they are usually very relevant)
    for dv in dynamic_videos:
        resource_list.append(dv)

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
            "content": res.content,
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


@router.get("/subject-resources/{subject_code}")
def get_all_subject_resources(
    subject_code: str,
    language: str = "All",
    risk_level: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all resources for a subject, optionally filtered by the student's risk level.
    
    Resource level mapping:
    - Low risk   → Advanced resources (they're already performing well)
    - Medium risk → Advanced + Intermediate + Beginner (broad access)
    - High risk  → Beginner resources (foundational help first)
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access resources")

    # Map risk level to allowed resource levels (cumulative access)
    # High   → Basic only (foundational help)
    # Medium → Basic + Intermediate
    # Low    → Basic + Intermediate + Advanced (all content)
    RISK_RESOURCE_MAP = {
        "High":   ["Basic"],
        "Medium": ["Basic", "Intermediate"],
        "Low":    ["Basic", "Intermediate", "Advanced"],
    }
    allowed_levels = RISK_RESOURCE_MAP.get(risk_level, ["Basic", "Intermediate", "Advanced"])

    # Build query for the subject (case-insensitive match)
    query = db.query(LearningResource).filter(
        (LearningResource.dept == current_user.dept) | (LearningResource.dept == None),
        (func.lower(LearningResource.subject_code) == subject_code.lower()) | (LearningResource.subject_code == None)
    )

    if language and language != "All":
        query = query.filter(
            (LearningResource.language == language) | 
            (LearningResource.language == "English")
        )

    resources = query.all()

    # Get completed resource IDs for this student
    student = _get_student(db, current_user)
    completed_records = db.query(StudentLearningProgress).filter(
        StudentLearningProgress.reg_no == student.reg_no,
        StudentLearningProgress.completed == 1
    ).all()
    completed_ids = {r.resource_id for r in completed_records}

    # Dynamic YouTube Recommendations
    subject = db.query(models.Subject).filter(
        func.lower(models.Subject.subject_code) == subject_code.lower()
    ).first()
    subject_title = subject.subject_title if subject else subject_code
    
    # Try to get or refresh the student's plan
    plan = db.query(PersonalizedLearningPlan).filter(
        PersonalizedLearningPlan.reg_no == student.reg_no,
        PersonalizedLearningPlan.subject_code == subject_code,
        PersonalizedLearningPlan.is_active == 1
    ).first()
    
    current_risk_data = ml_service.calculate_subject_risk(db, student.reg_no, subject_code)
    current_risk = current_risk_data.get('risk_level', 'Low')

    if plan:
        if plan.risk_level != current_risk:
            print(f"DEBUG: Risk discrepancy detected for {subject_code} ({plan.risk_level} vs {current_risk}). Regenerating plan.")
            plan = generate_plan_for_subject(db, student.reg_no, subject_code)
    else:
        # Auto-generate if no plan exists
        plan = generate_plan_for_subject(db, student.reg_no, subject_code)
    
    plan_units = plan.units.split(",") if plan and plan.units else ["1"]
    plan_units_set = set(plan_units)
    
    # 1. Dynamic YouTube Recommendations (First)
    dynamic_videos = fetch_youtube_recommendations(
        db, 
        student.reg_no, 
        subject_code, 
        subject_title,
        plan_units, 
        current_risk, # Use live predicted risk
        language if language != "All" else "English"
    )

    # Format the response
    resource_list = []
    
    # Add dynamic videos first
    for dv in dynamic_videos:
        resource_list.append(dv)
        
    # 2. Add filtered static resources
    for res in resources:
        # If user has a plan with specific units, only show those units' resources
        # If resource has no unit, include it by default
        if not res.unit or not plan_units_set:
            should_include = True
        else:
            res_units = set(res.unit.split(","))
            should_include = bool(plan_units_set & res_units)

        if not should_include:
            continue
        res_sc = (getattr(res, 'subject_code', None) or '').lower()
        if res_sc and res_sc != subject_code.lower():
            continue

        # Filter by resource level based on risk (allow null resource_level through)
        if allowed_levels and res.resource_level and res.resource_level not in allowed_levels:
            continue
            
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
            "content": res.content,
            "is_completed": res.resource_id in completed_ids,
            "is_preferred_type": False, # Neutral outside plan context
        })

    # Parse practice schedule and weekly goals for the response
    plan_data = None
    if plan:
        practice_data = None
        goals_data = None
        try:
            if plan.practice_schedule:
                practice_data = json.loads(plan.practice_schedule)
            if plan.weekly_goals:
                goals_data = json.loads(plan.weekly_goals)
        except Exception:
            pass
            
        plan_data = {
            "id": plan.id,
            "risk_level": plan.risk_level,
            "focus_type": plan.focus_type,
            "units": plan.units,
            "skill_category": plan.skill_category,
            "resource_level": plan.resource_level,
            "latest_assessment": plan.latest_assessment,
            "pending_choice": (plan.risk_level == "Low" and plan.focus_type == "Pending Choice"),
            "available_skills": AVAILABLE_SKILLS if (plan.risk_level == "Low" and plan.focus_type == "Pending Choice") else None,
            "practice_schedule": practice_data,
            "weekly_goals": goals_data,
        }

    return {
        "plan": plan_data,
        "resources": resource_list,
        "progress": {
            "total": len(resource_list),
            "completed": len([r for r in resource_list if r.get('is_completed', False)]),
            "percentage": 0 # Not tracking plan progress here
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
                (LearningResource.subject_code == mark.subject_code) | (LearningResource.subject_code == None),
                (LearningResource.subject_code != None) | (LearningResource.resource_level == plan.resource_level)
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

    # Determine learning path preference
    learning_path_pref = getattr(student, 'learning_path_preference', None)

    # For Skill Development, use a static strategy (no Gemini needed)
    if learning_path_pref == "Skill Development":
        study_strategy = {
            "overall_risk": overall_risk,
            "recommendations": [
                "Focus on your selected skill area to build industry-ready capabilities.",
                "Complete all skill modules and related quizzes.",
                "Practice consistently and track your weekly progress.",
                "Apply skills in real-world mini-projects or tasks.",
            ],
            "time_allocation": {
                "Skill Practice": "50%",
                "Quizzes & Assessments": "30%",
                "Review & Reflection": "20%"
            }
        }
    else:
        # Academic path — use AI-powered strategy (with caching)
        cached_strategy = getattr(student, 'overall_study_strategy', None)
        if cached_strategy:
            try:
                study_strategy = json.loads(cached_strategy)
                # Basic sanity check: ensure it has correct overall_risk
                if study_strategy.get('overall_risk') != overall_risk:
                    # Risk changed, re-generate
                    study_strategy = gemini_service.generate_study_strategy(
                        overall_risk,
                        subject_statuses,
                        learning_path_pref
                    )
                    student.overall_study_strategy = json.dumps(study_strategy)
                    db.commit()
            except Exception:
                # Parse error, re-generate
                study_strategy = gemini_service.generate_study_strategy(
                    overall_risk,
                    subject_statuses,
                    learning_path_pref
                )
                student.overall_study_strategy = json.dumps(study_strategy)
                db.commit()
        else:
            # No cache, generate for first time
            study_strategy = gemini_service.generate_study_strategy(
                overall_risk,
                subject_statuses,
                learning_path_pref
            )
            student.overall_study_strategy = json.dumps(study_strategy)
            db.commit()

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
        "preferred_learning_type": preferred_type,
        "learning_path_preference": getattr(student, 'learning_path_preference', None),
        "learning_sub_preference": getattr(student, 'learning_sub_preference', None)
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
        # Check db first
        today = datetime.utcnow().date()
        recent_prediction = db.query(models.RiskPrediction).filter(
            models.RiskPrediction.reg_no == student.reg_no,
        ).order_by(models.RiskPrediction.prediction_date.desc()).first()
        
        if recent_prediction and recent_prediction.prediction_date.date() == today:
            risk_level = recent_prediction.risk_level
            risk_score = recent_prediction.risk_score
            risk_basis = f"Overall Risk: {risk_level} (Cached)"
        else:
            risk_data = ml_service.predict_risk(db, student.reg_no)
            ml_service.save_prediction(db, student.reg_no, risk_data)
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


# ─── YouTube Data API Integration ──────────────────────────────────────

def fetch_youtube_videos(query: str, max_results: int = 5) -> List[Dict[str, Any]]:
    """Fetch videos from YouTube Data API v3 based on a search query with filtering."""
    # Add negative filters to the query if not present
    if " -" not in query:
        query += " -experience -warning -shorts -vlog -update -notice -news"

    params = {
        "part": "snippet",
        "q": query,
        "type": "video",
        "maxResults": max_results + 5, # Fetch extra for filtering
        "key": YOUTUBE_API_KEY
    }
    
    try:
        response = requests.get(YOUTUBE_SEARCH_URL, params=params)
        response.raise_for_status()
        data = response.json()
        
        videos = []
        irrelevant_keywords = ["don't watch", "warning", "notice", "update", "experience", "vlog", "shorts", "news", "wrong"]
        
        for item in data.get("items", []):
            if len(videos) >= max_results: break
            
            video_id = item["id"]["videoId"]
            snippet = item["snippet"]
            title = snippet["title"]
            
            # Post-fetch filtering
            if any(kw in title.lower() for kw in irrelevant_keywords):
                continue

            videos.append({
                "video_id": video_id,
                "title": title,
                "description": snippet["description"],
                "thumbnail": snippet["thumbnails"]["high"]["url"],
                "video_url": f"{WATCH_URL_BASE}{video_id}",
                "embed_url": f"{EMBED_URL_BASE}{video_id}"
            })
        return videos
    except Exception as e:
        print(f"Error fetching YouTube videos: {e}")
        return []

@router.get("/learning-resources", response_model=schemas.LearningResourcesResponse)
def get_youtube_learning_resources(
    subject: str,
    unit: str,
    risk_level: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get personalized YouTube learning resources based on subject, unit, and risk level.
    Follows EduPulse rule-based personalized learning logic.
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access personalized resources")

    # 1. Generate search query based on risk level and functional requirements
    # Requirement: subject + "Unit" + unit_number + "Tamil"
    
    # Determine Focus Type and Resource Level based on risk
    focus_type = ""
    resource_level = ""
    
    risk_level_upper = risk_level.upper()
    
    if risk_level_upper == "HIGH":
        focus_type = "Academic Recovery"
        resource_level = "Basic"
    elif risk_level_upper == "MEDIUM":
        focus_type = "Academic Improvement"
        resource_level = "Intermediate"
    else: # LOW RISK
        focus_type = "Academic Enhancement"
        resource_level = "Advanced"
    
    search_query = f'"{subject}" Unit {unit} engineering lecture university syllabus'
    
    # 2. Check if we already have recommendations for this student, subject, and unit
    existing_recs = db.query(YouTubeRecommendation).filter(
        YouTubeRecommendation.reg_no == current_user.reg_no,
        YouTubeRecommendation.subject_code == subject,
        YouTubeRecommendation.unit == unit
    ).all()
    
    if existing_recs:
        # Return existing recommendations
        return {
            "subject": subject,
            "risk_level": risk_level,
            "focus_type": focus_type,
            "weak_unit": f"Unit {unit}",
            "recommended_videos": [
                {
                    "video_id": rec.video_id,
                    "title": rec.title,
                    "thumbnail": rec.thumbnail,
                    "video_url": rec.video_url
                } for rec in existing_recs
            ]
        }
    
    # 3. Call YouTube API
    videos = fetch_youtube_videos(search_query)
    
    # 4. Save results to database for history
    saved_videos = []
    for v in videos:
        # Check if this video was already recommended for this student/subject to avoid duplicates in history
        exists = db.query(YouTubeRecommendation).filter(
            YouTubeRecommendation.reg_no == current_user.reg_no,
            YouTubeRecommendation.subject_code == subject,
            YouTubeRecommendation.video_id == v["video_id"]
        ).first()
        
        if not exists:
            db_rec = YouTubeRecommendation(
                reg_no=current_user.reg_no,
                subject_code=subject,
                unit=unit,
                video_id=v["video_id"],
                title=v["title"],
                thumbnail=v["thumbnail"],
                video_url=v["video_url"],
                risk_level=risk_level
            )
            db.add(db_rec)
            
        saved_videos.append({
            "video_id": v["video_id"],
            "title": v["title"],
            "thumbnail": v["thumbnail"],
            "video_url": v["video_url"]
        })
    
    db.commit()
    
    return {
        "subject": subject,
        "risk_level": risk_level,
        "focus_type": focus_type,
        "weak_unit": f"Unit {unit}",
        "recommended_videos": saved_videos
    }


# ─── Skill Development — Gemini Content + YouTube + Quiz ─────────────────────

SKILL_YOUTUBE_QUERIES = {
    "Communication": "communication skills engineering students placement interview",
    "Programming": "programming problem solving coding interview engineering",
    "Aptitude": "aptitude quantitative reasoning placement preparation engineering",
    "Critical Thinking": "critical thinking problem solving engineering students",
    "Leadership": "leadership skills team management engineering college students",
}


def fetch_skill_youtube_videos(db: Session, skill_category: str, language: str = "English") -> list:
    """
    Fetch YouTube videos for a skill category — cached in YouTubeRecommendation with subject_code='SKILL'.
    Returns list of {video_id, title, thumbnail, video_url}.
    """
    SKILL_SUBJECT_CODE = "SKILL"

    # Check cache
    cached = db.query(YouTubeRecommendation).filter(
        YouTubeRecommendation.subject_code == SKILL_SUBJECT_CODE,
        YouTubeRecommendation.unit == skill_category,
        YouTubeRecommendation.language == language
    ).all()

    if cached:
        return [
            {
                "video_id": c.video_id,
                "title": c.title,
                "thumbnail": c.thumbnail,
                "video_url": c.video_url,
            }
            for c in cached
        ]

    if not YOUTUBE_API_KEY:
        return []

    base_query = SKILL_YOUTUBE_QUERIES.get(skill_category, f"{skill_category} skills engineering")
    if language == "Tamil":
        base_query += " in Tamil"

    try:
        params = {
            "part": "snippet",
            "q": base_query,
            "key": YOUTUBE_API_KEY,
            "maxResults": 8,
            "type": "video",
            "videoEmbeddable": "true",
            "relevanceLanguage": "ta" if language == "Tamil" else "en",
        }
        resp = requests.get(YOUTUBE_SEARCH_URL, params=params, timeout=10)
        resp.raise_for_status()
        data = resp.json()

        results = []
        irrelevant_kw = ["don't watch", "warning", "notice", "experience", "vlog", "shorts", "news", "wrong"]
        for item in data.get("items", []):
            if len(results) >= 5:
                break
            video_id = item["id"]["videoId"]
            title = item["snippet"]["title"]
            thumb_data = item["snippet"]["thumbnails"]
            thumb = thumb_data.get("medium", thumb_data.get("default", {})).get("url", "")
            video_url = f"https://www.youtube.com/watch?v={video_id}"

            if any(kw in title.lower() for kw in irrelevant_kw):
                continue

            rec = YouTubeRecommendation(
                reg_no="SKILL",
                subject_code=SKILL_SUBJECT_CODE,
                unit=skill_category,
                video_id=video_id,
                title=title,
                thumbnail=thumb,
                video_url=video_url,
                risk_level="Low",
                language=language,
            )
            db.add(rec)
            results.append({
                "video_id": video_id,
                "title": title,
                "thumbnail": thumb,
                "video_url": video_url,
            })

        db.commit()
        return results

    except Exception as e:
        print(f"ERROR fetching skill YouTube videos for {skill_category}: {e}")
        return []


@router.get("/skill-content")
def get_skill_content(
    skill: str,
    language: str = "English",
    sub_category: str = Query(None),
    level: str = Query("Beginner"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Returns Gemini-generated learning content + YouTube videos + AI quiz for a given skill.
    Supports sub-categories (e.g. Python) and levels (Basic/Medium/Advanced) for Programming.
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access skill content")

    VALID_SKILLS = ["Communication", "Programming", "Aptitude", "Critical Thinking", "Leadership"]
    if skill not in VALID_SKILLS:
        raise HTTPException(status_code=400, detail=f"Invalid skill. Choose from: {VALID_SKILLS}")

    # ── 0. Find or Create Persistent Resource for Progress Tracking ──
    # Include level and sub_category in the URL to separate different courses
    resource_url = f"ai_skill://{skill}/{level}"
    if sub_category:
        resource_url += f"/{sub_category}"
        
    resource = db.query(LearningResource).filter(
        LearningResource.url == resource_url,
        LearningResource.language == language
    ).first()

    if not resource:
        resource = LearningResource(
            title=f"{skill} {sub_category or ''} ({level}) Master Guide".strip(),
            description=f"AI-generated technical roadmap for {skill}.",
            url=resource_url,
            type="course",
            skill_category=skill,
            language=language,
            tags=f"skill,ai,{skill.lower()},{level.lower()}"
        )
        db.add(resource)
        db.commit()
        db.refresh(resource)

    # ── 1. Check Cache ────────────────────────────────────────────────────────
    if resource.content:
        try:
            cached_data = json.loads(resource.content)
            # Fetch YouTube videos dynamically even if content is cached
            video_query = skill
            if sub_category: video_query = f"{sub_category} {level}"
            youtube_videos = fetch_skill_youtube_videos(db, video_query, language)
            
            cached_data["youtube_videos"] = youtube_videos
            cached_data["resource_id"] = resource.resource_id # Inject real ID
            
            # Backwards compatibility for old cached data missing project details
            if "project" in cached_data:
                topic = sub_category or skill
                if "objective" not in cached_data["project"]:
                    cached_data["project"]["objective"] = f"Apply {level} {topic} principles to build a functional prototype."
                if "tech_stack" not in cached_data["project"]:
                    cached_data["project"]["tech_stack"] = [topic, "Standard Library"]
                    
            return cached_data
        except Exception as e:
            print(f"DEBUG: Cache corrupted for {resource_url}, regenerating... Error: {e}")
            pass

    # ── 2. Generate Gemini Content ────────────────────────────────────────────
    content_data = gemini_service.generate_skill_content(skill, sub_category=sub_category, level=level)
    summary = content_data.get("summary", "")
    sections = content_data.get("sections", [])
    project = content_data.get("project", {})

    # ── 3. YouTube Videos ─────────────
    video_query = skill
    if sub_category: video_query = f"{sub_category} {level}"
    youtube_videos = fetch_skill_youtube_videos(db, video_query, language)

    # ── 4. Generate Quiz ──────────────────────────────────────────────────────
    quiz_questions = gemini_service.generate_skill_quiz(skill, difficulty=level, sub_category=sub_category)

    # ── 5. Save to Cache ──────────────────────────────────────────────────────
    final_response = {
        "resource_id": resource.resource_id,
        "skill": skill,
        "sub_category": sub_category,
        "level": level,
        "summary": summary,
        "sections": sections,
        "project": project,
        "youtube_videos": youtube_videos,
        "quiz": quiz_questions,
    }

    # Save everything EXCEPT youtube videos to the cache (since YT has its own cache logic)
    cache_payload = final_response.copy()
    cache_payload.pop("youtube_videos", None)
    
    resource.content = json.dumps(cache_payload)
    db.commit()

    return final_response

