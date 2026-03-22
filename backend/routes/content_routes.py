from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from auth import get_current_user
from models import User, StudentCSE, StudentECE, StudentEEE, StudentMECH, StudentCIVIL, StudentBIO, StudentAIDS
import schemas
from gemini_service import generate_learning_content, generate_quiz_questions

router = APIRouter(prefix="/api/content", tags=["Content Generation"])

# Student model mapping
STUDENT_MODEL_MAP = {
    'CSE': StudentCSE, 'ECE': StudentECE, 'EEE': StudentEEE,
    'MECH': StudentMECH, 'CIVIL': StudentCIVIL, 'BIO': StudentBIO, 'AIDS': StudentAIDS,
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


@router.post("/generate", response_model=schemas.ContentGenerationResponse)
def generate_content(
    request: schemas.ContentGenerationRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate comprehensive learning content for a subject unit.
    
    Requires:
    - subject_name: Name of the subject (e.g., "Data Structures")
    - unit_number: Unit number (1-5)
    - topic: Specific topic to cover
    - learning_preference (optional): "text", "visual", or "mixed"
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access content generation")
    
    student = _get_student(db, current_user)
    
    # Determine risk level from student's current marks (if available)
    risk_level = "MEDIUM"  # Default
    
    print(f"DEBUG: Generating content for {request.subject_name} Unit {request.unit_number}...")
    
    # Generate content using Gemini
    content_data = generate_learning_content(
        subject_name=request.subject_name,
        unit_number=request.unit_number,
        topic=request.topic,
        risk_level=risk_level
    )
    
    if not content_data:
        raise HTTPException(status_code=500, detail="Failed to generate content")
    
    # Build response
    return schemas.ContentGenerationResponse(
        subject=request.subject_name,
        unit=request.unit_number,
        topic=request.topic,
        title=content_data.get("title", ""),
        introduction=content_data.get("introduction", ""),
        sections=[
            schemas.ContentSection(
                title=section.get("title", ""),
                content=section.get("content", ""),
                key_points=section.get("key_points", []),
                examples=section.get("examples", [])
            )
            for section in content_data.get("sections", [])
        ],
        summary=content_data.get("summary", ""),
        learning_objectives=content_data.get("learning_objectives", []),
        difficulty_level=content_data.get("difficulty_level", "Intermediate"),
        estimated_read_time=content_data.get("estimated_read_time", "")
    )


@router.post("/with-quiz", response_model=schemas.QuizWithContentResponse)
def generate_content_with_quiz(
    request: schemas.ContentGenerationRequest,
    unit_number: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate both learning content AND a quiz for the same topic.
    
    Returns both content and quiz in one response.
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access content generation")
    
    student = _get_student(db, current_user)
    
    risk_level = "MEDIUM"  # Default
    
    print(f"DEBUG: Generating content + quiz for {request.subject_name} Unit {unit_number}...")
    
    # Generate content
    content_data = generate_learning_content(
        subject_name=request.subject_name,
        unit_number=unit_number,
        topic=request.topic,
        risk_level=risk_level
    )
    
    if not content_data:
        raise HTTPException(status_code=500, detail="Failed to generate content")
    
    # Generate quiz
    quiz_data = generate_quiz_questions(
        subject_name=request.subject_name,
        unit_number=unit_number,
        risk_level=risk_level
    )
    
    if not quiz_data:
        raise HTTPException(status_code=500, detail="Failed to generate quiz")
    
    # Build content response
    content_response = schemas.ContentGenerationResponse(
        subject=request.subject_name,
        unit=unit_number,
        topic=request.topic,
        title=content_data.get("title", ""),
        introduction=content_data.get("introduction", ""),
        sections=[
            schemas.ContentSection(
                title=section.get("title", ""),
                content=section.get("content", ""),
                key_points=section.get("key_points", []),
                examples=section.get("examples", [])
            )
            for section in content_data.get("sections", [])
        ],
        summary=content_data.get("summary", ""),
        learning_objectives=content_data.get("learning_objectives", []),
        difficulty_level=content_data.get("difficulty_level", "Intermediate"),
        estimated_read_time=content_data.get("estimated_read_time", "")
    )
    
    # Build quiz response
    quiz_response = schemas.QuizGenerationResponse(
        subject=request.subject_name,
        unit=unit_number,
        risk_level=risk_level,
        total_questions=len(quiz_data),
        quiz=[
            schemas.QuizQuestionResponse(
                id=idx + 1,
                subject=request.subject_name,
                unit=unit_number,
                difficulty_level="Intermediate",
                question=q.get("question", ""),
                option_a=q.get("option_a", ""),
                option_b=q.get("option_b", ""),
                option_c=q.get("option_c", ""),
                option_d=q.get("option_d", ""),
                correct_answer=q.get("correct_answer", "")
            )
            for idx, q in enumerate(quiz_data)
        ]
    )
    
    return schemas.QuizWithContentResponse(
        content=content_response,
        quiz=quiz_response
    )


@router.get("/subjects/{subject_name}/topics")
def get_available_topics(
    subject_name: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of available topics for a subject (from curriculum).
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access this")
    
    # This would typically query a curriculum table
    # For now, return common topics for computer science subjects
    topics_map = {
        "Data Structures": [
            "Arrays and Linked Lists",
            "Stacks and Queues",
            "Trees and Graphs",
            "Sorting and Searching",
            "Hash Tables"
        ],
        "Database Systems": [
            "Relational Model",
            "SQL Basics",
            "Normalization",
            "Transactions",
            "Indexing"
        ],
        "Web Development": [
            "HTML & CSS Basics",
            "JavaScript Fundamentals",
            "REST APIs",
            "Databases for Web",
            "Frontend Frameworks"
        ],
        "Algorithm Design": [
            "Complexity Analysis",
            "Divide and Conquer",
            "Dynamic Programming",
            "Greedy Algorithms",
            "Graph Algorithms"
        ]
    }
    
    topics = topics_map.get(subject_name, [f"Unit {i}" for i in range(1, 6)])
    
    return {
        "subject": subject_name,
        "topics": topics,
        "total_topics": len(topics)
    }
