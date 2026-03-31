"""
OpenCode-based Content and Quiz Generation Routes

This module provides API endpoints for generating educational content and quizzes
using OpenCode AI integration.
"""

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import Optional, List
import logging
import asyncio

from database import get_db
from auth import get_current_user
from models import User, StudentCSE, StudentECE, StudentEEE, StudentMECH, StudentCIVIL, StudentBIO, StudentAIDS
import schemas
from opencode_service import (
    generate_content,
    generate_quiz,
    generate_content_and_quiz,
    GeneratedContent,
    GeneratedQuiz,
    get_server_url,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/opencode", tags=["OpenCode Content Generation"])

# Student model mapping
STUDENT_MODEL_MAP = {
    'CSE': StudentCSE,
    'ECE': StudentECE,
    'EEE': StudentEEE,
    'MECH': StudentMECH,
    'CIVIL': StudentCIVIL,
    'BIO': StudentBIO,
    'AIDS': StudentAIDS,
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


@router.post("/content/generate", response_model=schemas.ContentGenerationResponse)
async def generate_learning_content(
    request: schemas.ContentGenerationRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Generate comprehensive learning content using OpenCode AI.

    This endpoint uses OpenCode to generate structured, educational content
    for a specific subject unit and topic.

    Args:
        subject_name: Name of the subject (e.g., "Data Structures")
        unit_number: Unit number (1-5)
        topic: Specific topic to cover
        learning_preference: "text", "visual", or "mixed" (default: "text")

    Returns:
        ContentGenerationResponse with title, sections, objectives, and more

    Example:
        POST /api/opencode/content/generate
        {
            "subject_name": "Data Structures",
            "unit_number": 1,
            "topic": "Arrays and Linked Lists",
            "learning_preference": "mixed"
        }
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access content generation")

    try:
        student = _get_student(db, current_user)
        logger.info(f"Generating content for {request.subject_name} Unit {request.unit_number}")

        # Generate content asynchronously
        generated_content: Optional[GeneratedContent] = await generate_content(
            subject_name=request.subject_name,
            unit_number=request.unit_number,
            topic=request.topic,
            learning_preference=request.learning_preference or "text",
        )

        if not generated_content:
            raise HTTPException(
                status_code=500,
                detail="Failed to generate content. Please try again.",
            )

        # Convert to response format
        return schemas.ContentGenerationResponse(
            subject=request.subject_name,
            unit=request.unit_number,
            topic=request.topic,
            title=generated_content.title,
            introduction=generated_content.introduction,
            sections=[
                schemas.ContentSection(
                    title=section.title,
                    content=section.content,
                    key_points=section.key_points,
                    examples=section.examples,
                )
                for section in generated_content.sections
            ],
            summary=generated_content.summary,
            learning_objectives=generated_content.learning_objectives,
            difficulty_level=generated_content.difficulty_level,
            estimated_read_time=generated_content.estimated_read_time,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating content: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error during content generation")


@router.post("/quiz/generate")
async def generate_quiz_questions(
    subject_name: str,
    unit_number: int,
    num_questions: int = 5,
    difficulty_level: str = "Intermediate",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Generate a quiz using OpenCode AI with validated JSON output.

    This endpoint generates multiple-choice quiz questions with automatic
    validation to ensure quality and consistency.

    Args:
        subject_name: Name of the subject
        unit_number: Unit number
        num_questions: Number of questions to generate (1-20, default: 5)
        difficulty_level: "Beginner", "Intermediate", or "Advanced"

    Returns:
        GeneratedQuiz with validated questions

    Example:
        POST /api/opencode/quiz/generate
        {
            "subject_name": "Data Structures",
            "unit_number": 1,
            "num_questions": 5,
            "difficulty_level": "Intermediate"
        }
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access quiz generation")

    # Validate inputs
    if num_questions < 1 or num_questions > 20:
        raise HTTPException(status_code=400, detail="num_questions must be between 1 and 20")

    if difficulty_level not in ["Beginner", "Intermediate", "Advanced"]:
        raise HTTPException(
            status_code=400,
            detail="difficulty_level must be one of: Beginner, Intermediate, Advanced",
        )

    try:
        student = _get_student(db, current_user)
        logger.info(f"Generating quiz for {subject_name} Unit {unit_number}")

        # Generate quiz asynchronously
        generated_quiz: Optional[GeneratedQuiz] = await generate_quiz(
            subject_name=subject_name,
            unit_number=unit_number,
            num_questions=num_questions,
            difficulty_level=difficulty_level,
        )

        if not generated_quiz:
            raise HTTPException(
                status_code=500,
                detail="Failed to generate quiz. Please try again.",
            )

        # Convert to response format
        return {
            "title": generated_quiz.title,
            "subject": generated_quiz.subject,
            "unit": generated_quiz.unit,
            "total_questions": generated_quiz.total_questions,
            "questions": [
                {
                    "question": q.question,
                    "options": q.options,
                    "correct_answer": q.correct_answer,
                    "explanation": q.explanation,
                    "difficulty": q.difficulty,
                }
                for q in generated_quiz.questions
            ],
            "difficulty_distribution": generated_quiz.difficulty_distribution,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating quiz: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error during quiz generation")


@router.post("/content-and-quiz/generate", response_model=schemas.QuizWithContentResponse)
async def generate_content_with_quiz(
    request: schemas.ContentGenerationRequest,
    num_quiz_questions: int = 5,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Generate both learning content AND a quiz in one request.

    This endpoint efficiently generates both content and quiz concurrently,
    saving time and ensuring consistency between them.

    Args:
        subject_name: Name of the subject
        unit_number: Unit number
        topic: Specific topic
        learning_preference: "text", "visual", or "mixed"
        num_quiz_questions: Number of quiz questions (default: 5)

    Returns:
        QuizWithContentResponse containing both content and quiz

    Example:
        POST /api/opencode/content-and-quiz/generate
        {
            "subject_name": "Data Structures",
            "unit_number": 1,
            "topic": "Arrays and Linked Lists",
            "learning_preference": "mixed",
            "num_quiz_questions": 5
        }
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access content generation")

    if num_quiz_questions < 1 or num_quiz_questions > 20:
        raise HTTPException(status_code=400, detail="num_quiz_questions must be between 1 and 20")

    try:
        student = _get_student(db, current_user)
        logger.info(
            f"Generating content + quiz for {request.subject_name} Unit {request.unit_number}"
        )

        # Generate both concurrently for efficiency
        generated_content, generated_quiz = await generate_content_and_quiz(
            subject_name=request.subject_name,
            unit_number=request.unit_number,
            topic=request.topic,
            num_quiz_questions=num_quiz_questions,
        )

        if not generated_content or not generated_quiz:
            raise HTTPException(
                status_code=500,
                detail="Failed to generate content and quiz. Please try again.",
            )

        # Build content response
        content_response = schemas.ContentGenerationResponse(
            subject=request.subject_name,
            unit=request.unit_number,
            topic=request.topic,
            title=generated_content.title,
            introduction=generated_content.introduction,
            sections=[
                schemas.ContentSection(
                    title=section.title,
                    content=section.content,
                    key_points=section.key_points,
                    examples=section.examples,
                )
                for section in generated_content.sections
            ],
            summary=generated_content.summary,
            learning_objectives=generated_content.learning_objectives,
            difficulty_level=generated_content.difficulty_level,
            estimated_read_time=generated_content.estimated_read_time,
        )

        # Build quiz response
        quiz_response = schemas.QuizGenerationResponse(
            subject=request.subject_name,
            unit=request.unit_number,
            risk_level="MEDIUM",  # Default risk level
            total_questions=generated_quiz.total_questions,
            quiz=[
                schemas.QuizQuestionResponse(
                    id=idx + 1,
                    subject=request.subject_name,
                    unit=request.unit_number,
                    difficulty_level=q.difficulty,
                    question=q.question,
                    option_a=q.options[0],
                    option_b=q.options[1],
                    option_c=q.options[2],
                    option_d=q.options[3],
                    correct_answer=chr(65 + q.correct_answer),  # Convert 0-3 to A-D
                )
                for idx, q in enumerate(generated_quiz.questions)
            ],
        )

        return schemas.QuizWithContentResponse(
            content=content_response,
            quiz=quiz_response,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating content and quiz: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error during content and quiz generation",
        )


@router.get("/health")
async def health_check():
    """
    Check if OpenCode service is available.

    Returns:
        Health status of the OpenCode integration
    """
    try:
        # Try to generate a simple content to verify OpenCode is working
        import aiohttp
        url = get_server_url()
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{url}/api/health", timeout=aiohttp.ClientTimeout(total=5)):
                return {
                    "status": "healthy",
                    "service": "opencode",
                    "message": "OpenCode service is available",
                }
    except Exception as e:
        logger.warning(f"OpenCode health check failed: {str(e)}")
        return {
            "status": "unavailable",
            "service": "opencode",
            "message": f"OpenCode service is not available: {str(e)}",
        }


@router.get("/subjects/{subject_name}/topics")
def get_available_topics(
    subject_name: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get list of available topics for a subject.

    Args:
        subject_name: Name of the subject

    Returns:
        List of topics for the subject

    Example:
        GET /api/opencode/subjects/Data Structures/topics
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can access this")

    # Map of subjects to their topics
    topics_map = {
        "Data Structures": [
            "Arrays and Linked Lists",
            "Stacks and Queues",
            "Trees and Graphs",
            "Sorting and Searching",
            "Hash Tables",
        ],
        "Database Systems": [
            "Relational Model",
            "SQL Basics",
            "Normalization",
            "Transactions",
            "Indexing",
        ],
        "Web Development": [
            "HTML & CSS Basics",
            "JavaScript Fundamentals",
            "REST APIs",
            "Databases for Web",
            "Frontend Frameworks",
        ],
        "Algorithm Design": [
            "Complexity Analysis",
            "Divide and Conquer",
            "Dynamic Programming",
            "Greedy Algorithms",
            "Graph Algorithms",
        ],
        "Object-Oriented Programming": [
            "Classes and Objects",
            "Inheritance and Polymorphism",
            "Encapsulation",
            "Abstraction",
            "Design Patterns",
        ],
    }

    topics = topics_map.get(
        subject_name,
        [f"Unit {i}" for i in range(1, 6)],
    )

    return {
        "subject": subject_name,
        "topics": topics,
        "total_topics": len(topics),
    }
