"""
OpenCode Service Module

This module provides integration with OpenCode for content and quiz generation.
It uses the OpenCode Server API to leverage AI for generating educational content
and validated quizzes.
"""

import aiohttp
import asyncio
import json
import logging
from typing import Optional, Dict, List, Any
from pydantic import BaseModel
import config as cfg

logger = logging.getLogger(__name__)

def get_server_url():
    settings = cfg.get_settings()
    # If the setting is just a port or incomplete URL, fix it
    url = settings.opencode_base_url or "http://localhost:4096"
    # Ensure it doesn't end with /v1 if we are appending /api
    if url.endswith("/v1"):
        url = url[:-3]
    return url

OPENCODE_TIMEOUT = 30


class ContentSection(BaseModel):
    title: str
    content: str
    key_points: List[str]
    examples: List[str]


class QuizQuestion(BaseModel):
    question: str
    options: List[str]
    correct_answer: int
    explanation: str
    difficulty: str


class GeneratedContent(BaseModel):
    title: str
    introduction: str
    sections: List[ContentSection]
    summary: str
    learning_objectives: List[str]
    difficulty_level: str
    estimated_read_time: str


class GeneratedQuiz(BaseModel):
    title: str
    subject: str
    unit: int
    total_questions: int
    questions: List[QuizQuestion]
    difficulty_distribution: Dict[str, int]


async def _send_opencode_request(
    prompt: str,
    output_format: Optional[Dict[str, Any]] = None,
    session_id: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Send a request to OpenCode server and get AI-generated response.

    Args:
        prompt: The prompt to send to OpenCode
        output_format: Optional JSON schema for structured output
        session_id: Optional existing session ID

    Returns:
        Dictionary containing the AI response
    """
    try:
        async with aiohttp.ClientSession() as session:
            url = get_server_url()
            # First, create or get a session
            if not session_id:
                session_response = await session.post(
                    f"{url}/api/session",
                    json={"title": "Content Generation Session"},
                    timeout=aiohttp.ClientTimeout(total=OPENCODE_TIMEOUT),
                )
                session_data = await session_response.json()
                session_id = session_data.get("id")
                logger.info(f"Created OpenCode session: {session_id}")

            # Send prompt to session
            prompt_payload = {
                "parts": [{"type": "text", "text": prompt}],
                "model": {"providerID": "github-copilot", "modelID": "claude-sonnet-4.5"},
            }

            if output_format:
                prompt_payload["format"] = output_format

            response = await session.post(
                f"{url}/api/session/{session_id}/prompt",
                json=prompt_payload,
                timeout=aiohttp.ClientTimeout(total=OPENCODE_TIMEOUT),
            )

            if response.status != 200:
                error_text = await response.text()
                logger.error(f"OpenCode API error: {error_text}")
                raise Exception(f"OpenCode API returned {response.status}: {error_text}")

            result = await response.json()
            # print(f"DEBUG: OpenCode Response: {json.dumps(result, indent=2)}")
            logger.info(f"OpenCode Response received: {result.keys()}")
            return result

    except asyncio.TimeoutError:
        logger.error("OpenCode request timed out")
        raise Exception("OpenCode request timed out")
    except Exception as e:
        logger.error(f"Error communicating with OpenCode: {str(e)}")
        raise


async def generate_content(
    subject_name: str,
    unit_number: int,
    topic: str,
    learning_preference: str = "mixed",
) -> Optional[GeneratedContent]:
    """
    Generate comprehensive learning content for a subject unit using OpenCode.

    Args:
        subject_name: Name of the subject (e.g., "Data Structures")
        unit_number: Unit number (1-5)
        topic: Specific topic to cover
        learning_preference: "text", "visual", or "mixed"

    Returns:
        GeneratedContent object or None if generation fails
    """
    try:
        prompt = f"""Generate comprehensive learning content for the following:

Subject: {subject_name}
Unit: {unit_number}
Topic: {topic}
Learning Preference: {learning_preference}

Please create detailed, well-structured educational content with:
- Clear title
- Engaging introduction
- 3-4 main sections with key points and examples
- Summary of important concepts
- Learning objectives (3-4 objectives)
- Difficulty level assessment
- Estimated read time

Format the response as JSON with this structure:
{{
  "title": "string",
  "introduction": "string",
  "sections": [
    {{
      "title": "string",
      "content": "string",
      "key_points": ["string"],
      "examples": ["string"]
    }}
  ],
  "summary": "string",
  "learning_objectives": ["string"],
  "difficulty_level": "Beginner|Intermediate|Advanced",
  "estimated_read_time": "string (e.g., '15 minutes')"
}}"""

        output_format = {
            "type": "json_schema",
            "schema": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "introduction": {"type": "string"},
                    "sections": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "title": {"type": "string"},
                                "content": {"type": "string"},
                                "key_points": {"type": "array", "items": {"type": "string"}},
                                "examples": {"type": "array", "items": {"type": "string"}},
                            },
                            "required": ["title", "content", "key_points", "examples"],
                        },
                    },
                    "summary": {"type": "string"},
                    "learning_objectives": {"type": "array", "items": {"type": "string"}},
                    "difficulty_level": {"type": "string"},
                    "estimated_read_time": {"type": "string"},
                },
                "required": [
                    "title",
                    "introduction",
                    "sections",
                    "summary",
                    "learning_objectives",
                    "difficulty_level",
                    "estimated_read_time",
                ],
            },
        }

        result = await _send_opencode_request(prompt, output_format)

        # Extract structured output from response
        structured_output = result.get("data", {}).get("info", {}).get("structured_output")

        if structured_output:
            return GeneratedContent(**structured_output)

        return None

    except Exception as e:
        logger.error(f"Error generating content: {str(e)}")
        return None


async def generate_quiz(
    subject_name: str,
    unit_number: int,
    num_questions: int = 5,
    difficulty_level: str = "Intermediate",
) -> Optional[GeneratedQuiz]:
    """
    Generate a quiz with validated JSON output using OpenCode.

    Args:
        subject_name: Name of the subject
        unit_number: Unit number
        num_questions: Number of questions to generate (default 5)
        difficulty_level: "Beginner", "Intermediate", or "Advanced"

    Returns:
        GeneratedQuiz object or None if generation fails
    """
    try:
        prompt = f"""Generate a {num_questions}-question quiz for the following:

Subject: {subject_name}
Unit: {unit_number}
Difficulty Level: {difficulty_level}

Create {num_questions} multiple-choice questions with:
- Clear, well-formulated questions
- 4 distinct options (A, B, C, D)
- Correct answer indication
- Brief explanation for the correct answer
- Difficulty classification

Return as JSON with this exact structure:
{{
  "title": "Quiz: {subject_name} Unit {unit_number}",
  "subject": "{subject_name}",
  "unit": {unit_number},
  "total_questions": {num_questions},
  "questions": [
    {{
      "question": "string",
      "options": ["string", "string", "string", "string"],
      "correct_answer": 0-3,
      "explanation": "string",
      "difficulty": "Beginner|Intermediate|Advanced"
    }}
  ],
  "difficulty_distribution": {{
    "Beginner": 0,
    "Intermediate": 0,
    "Advanced": 0
  }}
}}

Ensure:
- Exactly {num_questions} questions in the array
- All options are distinct and reasonable
- Explanations are educational and concise
- Difficulty distribution sums to {num_questions}"""

        output_format = {
            "type": "json_schema",
            "schema": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "subject": {"type": "string"},
                    "unit": {"type": "integer"},
                    "total_questions": {"type": "integer"},
                    "questions": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "question": {"type": "string"},
                                "options": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "minItems": 4,
                                    "maxItems": 4,
                                },
                                "correct_answer": {"type": "integer", "minimum": 0, "maximum": 3},
                                "explanation": {"type": "string"},
                                "difficulty": {"type": "string"},
                            },
                            "required": ["question", "options", "correct_answer", "explanation", "difficulty"],
                        },
                        "minItems": num_questions,
                    },
                    "difficulty_distribution": {
                        "type": "object",
                        "properties": {
                            "Beginner": {"type": "integer"},
                            "Intermediate": {"type": "integer"},
                            "Advanced": {"type": "integer"},
                        },
                    },
                },
                "required": ["title", "subject", "unit", "total_questions", "questions"],
            },
        }

        result = await _send_opencode_request(prompt, output_format)

        # Extract structured output from response
        structured_output = result.get("data", {}).get("info", {}).get("structured_output")

        if structured_output:
            return GeneratedQuiz(**structured_output)

        return None

    except Exception as e:
        logger.error(f"Error generating quiz: {str(e)}")
        return None


async def generate_content_and_quiz(
    subject_name: str,
    unit_number: int,
    topic: str,
    num_quiz_questions: int = 5,
):
    """
    Generate both content and quiz concurrently for efficiency.

    Args:
        subject_name: Name of the subject
        unit_number: Unit number
        topic: Specific topic
        num_quiz_questions: Number of quiz questions

    Returns:
        Tuple of (GeneratedContent, GeneratedQuiz)
    """
    try:
        results = await asyncio.gather(
            generate_content(subject_name, unit_number, topic),
            generate_quiz(subject_name, unit_number, num_quiz_questions),
            return_exceptions=False,
        )

        content = results[0] if len(results) > 0 else None
        quiz = results[1] if len(results) > 1 else None

        return content, quiz

    except Exception as e:
        logger.error(f"Error in concurrent generation: {str(e)}")
        return None, None
