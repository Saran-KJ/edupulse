"""
OpenCode Content and Quiz Generation - Usage Examples & Testing

This file demonstrates how to use the OpenCode API endpoints for 
content and quiz generation.
"""

import asyncio
import aiohttp
import json
from typing import Optional, Dict, Any

# Configuration
API_BASE_URL = "http://localhost:8000"  # EduPulse Backend
OPENCODE_SERVER_URL = "http://localhost:4096"  # OpenCode Server

# Default test credentials
TEST_STUDENT_EMAIL = "student@edupulse.com"
TEST_STUDENT_PASSWORD = "student123"


class OpencodeTestClient:
    """Test client for OpenCode content and quiz generation endpoints."""

    def __init__(self, base_url: str = API_BASE_URL):
        self.base_url = base_url
        self.token: Optional[str] = None
        self.session: Optional[aiohttp.ClientSession] = None

    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()

    async def login(self, email: str, password: str) -> bool:
        """Login and get JWT token."""
        if not self.session:
            self.session = aiohttp.ClientSession()

        try:
            # OAuth2PasswordRequestForm expects form-data, not JSON
            # Fields must be 'username' and 'password'
            async with self.session.post(
                f"{self.base_url}/api/auth/login",
                data={"username": email, "password": password},
            ) as response:
                if response.status == 200:
                    data = await response.json()
                    self.token = data.get("access_token")
                    print(f"✅ Login successful. Token: {self.token[:20]}...")
                    return True
                else:
                    error_detail = await response.text()
                    print(f"❌ Login failed: {response.status} - {error_detail}")
                    return False
        except Exception as e:
            print(f"❌ Login error: {e}")
            return False

    def _get_headers(self) -> Dict[str, str]:
        """Get request headers with auth token."""
        headers = {"Content-Type": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        return headers

    async def generate_content(
        self,
        subject_name: str,
        unit_number: int,
        topic: str,
        learning_preference: str = "mixed",
    ) -> Optional[Dict[str, Any]]:
        """Generate learning content."""
        if not self.session:
            self.session = aiohttp.ClientSession()

        payload = {
            "subject_name": subject_name,
            "unit_number": unit_number,
            "topic": topic,
            "learning_preference": learning_preference,
        }

        try:
            async with self.session.post(
                f"{self.base_url}/api/opencode/content/generate",
                json=payload,
                headers=self._get_headers(),
            ) as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ Content generated: {data.get('title', 'Untitled')}")
                    return data
                else:
                    error = await response.text()
                    print(f"❌ Content generation failed: {error}")
                    return None
        except Exception as e:
            print(f"❌ Content generation error: {e}")
            return None

    async def generate_quiz(
        self,
        subject_name: str,
        unit_number: int,
        num_questions: int = 5,
        difficulty_level: str = "Intermediate",
    ) -> Optional[Dict[str, Any]]:
        """Generate quiz questions."""
        if not self.session:
            self.session = aiohttp.ClientSession()

        params = {
            "subject_name": subject_name,
            "unit_number": unit_number,
            "num_questions": num_questions,
            "difficulty_level": difficulty_level,
        }

        try:
            async with self.session.post(
                f"{self.base_url}/api/opencode/quiz/generate",
                params=params,
                headers=self._get_headers(),
            ) as response:
                if response.status == 200:
                    data = await response.json()
                    print(
                        f"✅ Quiz generated: {data.get('total_questions', 0)} questions"
                    )
                    return data
                else:
                    error = await response.text()
                    print(f"❌ Quiz generation failed: {error}")
                    return None
        except Exception as e:
            print(f"❌ Quiz generation error: {e}")
            return None

    async def generate_content_and_quiz(
        self,
        subject_name: str,
        unit_number: int,
        topic: str,
        learning_preference: str = "mixed",
        num_quiz_questions: int = 5,
    ) -> Optional[Dict[str, Any]]:
        """Generate content and quiz together."""
        if not self.session:
            self.session = aiohttp.ClientSession()

        payload = {
            "subject_name": subject_name,
            "unit_number": unit_number,
            "topic": topic,
            "learning_preference": learning_preference,
        }

        params = {"num_quiz_questions": num_quiz_questions}

        try:
            async with self.session.post(
                f"{self.base_url}/api/opencode/content-and-quiz/generate",
                json=payload,
                params=params,
                headers=self._get_headers(),
            ) as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ Content + Quiz generated")
                    return data
                else:
                    error = await response.text()
                    print(f"❌ Content + Quiz generation failed: {error}")
                    return None
        except Exception as e:
            print(f"❌ Content + Quiz generation error: {e}")
            return None

    async def get_topics(self, subject_name: str) -> Optional[Dict[str, Any]]:
        """Get available topics for a subject."""
        if not self.session:
            self.session = aiohttp.ClientSession()

        try:
            async with self.session.get(
                f"{self.base_url}/api/opencode/subjects/{subject_name}/topics",
                headers=self._get_headers(),
            ) as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ Topics retrieved: {len(data.get('topics', []))} topics")
                    return data
                else:
                    print(f"❌ Failed to get topics: {response.status}")
                    return None
        except Exception as e:
            print(f"❌ Error getting topics: {e}")
            return None

    async def check_health(self) -> bool:
        """Check OpenCode service health."""
        if not self.session:
            self.session = aiohttp.ClientSession()

        try:
            async with self.session.get(
                f"{self.base_url}/api/opencode/health",
                headers=self._get_headers(),
            ) as response:
                if response.status == 200:
                    data = await response.json()
                    status = data.get("status")
                    print(f"✅ OpenCode Service Status: {status}")
                    return status == "healthy"
                else:
                    print(f"❌ Health check failed: {response.status}")
                    return False
        except Exception as e:
            print(f"❌ Health check error: {e}")
            return False


async def example_1_basic_content_generation():
    """Example 1: Generate content for a topic."""
    print("\n" + "=" * 60)
    print("EXAMPLE 1: Basic Content Generation")
    print("=" * 60)

    async with OpencodeTestClient() as client:
        # Login
        if not await client.login(TEST_STUDENT_EMAIL, TEST_STUDENT_PASSWORD):
            print("Cannot proceed without login")
            return

        # Generate content
        content = await client.generate_content(
            subject_name="Data Structures",
            unit_number=1,
            topic="Arrays and Linked Lists",
            learning_preference="mixed",
        )

        if content:
            print("\n📚 Content Generated:")
            print(f"   Title: {content.get('title')}")
            print(f"   Difficulty: {content.get('difficulty_level')}")
            print(f"   Read Time: {content.get('estimated_read_time')}")
            print(f"   Sections: {len(content.get('sections', []))}")
            print(
                f"   Learning Objectives: {len(content.get('learning_objectives', []))}"
            )


async def example_2_quiz_generation():
    """Example 2: Generate a quiz."""
    print("\n" + "=" * 60)
    print("EXAMPLE 2: Quiz Generation")
    print("=" * 60)

    async with OpencodeTestClient() as client:
        if not await client.login(TEST_STUDENT_EMAIL, TEST_STUDENT_PASSWORD):
            print("Cannot proceed without login")
            return

        quiz = await client.generate_quiz(
            subject_name="Data Structures",
            unit_number=1,
            num_questions=5,
            difficulty_level="Intermediate",
        )

        if quiz:
            print("\n📝 Quiz Generated:")
            print(f"   Subject: {quiz.get('subject')}")
            print(f"   Total Questions: {quiz.get('total_questions')}")
            print(f"   Questions: {len(quiz.get('questions', []))}")
            
            # Show first question
            questions = quiz.get("questions", [])
            if questions:
                q1 = questions[0]
                print(f"\n   First Question:")
                print(f"   Q: {q1.get('question')[:50]}...")
                print(f"   Correct Answer: {q1.get('correct_answer')}")


async def example_3_content_and_quiz():
    """Example 3: Generate content and quiz together."""
    print("\n" + "=" * 60)
    print("EXAMPLE 3: Content + Quiz Generation (Concurrent)")
    print("=" * 60)

    async with OpencodeTestClient() as client:
        if not await client.login(TEST_STUDENT_EMAIL, TEST_STUDENT_PASSWORD):
            print("Cannot proceed without login")
            return

        result = await client.generate_content_and_quiz(
            subject_name="Data Structures",
            unit_number=1,
            topic="Arrays and Linked Lists",
            learning_preference="mixed",
            num_quiz_questions=5,
        )

        if result:
            content = result.get("content", {})
            quiz = result.get("quiz", {})

            print("\n📚📝 Content & Quiz Generated:")
            print(f"   Content Title: {content.get('title')}")
            print(f"   Quiz Title: {quiz.get('quiz', [{}])[0] if quiz.get('quiz') else 'N/A'}")
            print(f"   Total Questions: {quiz.get('total_questions')}")
            print(f"   Content Sections: {len(content.get('sections', []))}")


async def example_4_get_available_topics():
    """Example 4: Get available topics for a subject."""
    print("\n" + "=" * 60)
    print("EXAMPLE 4: Get Available Topics")
    print("=" * 60)

    async with OpencodeTestClient() as client:
        if not await client.login(TEST_STUDENT_EMAIL, TEST_STUDENT_PASSWORD):
            print("Cannot proceed without login")
            return

        topics = await client.get_topics("Data Structures")

        if topics:
            print("\n📋 Available Topics:")
            for topic in topics.get("topics", []):
                print(f"   - {topic}")


async def example_5_service_health():
    """Example 5: Check OpenCode service health."""
    print("\n" + "=" * 60)
    print("EXAMPLE 5: Service Health Check")
    print("=" * 60)

    async with OpencodeTestClient() as client:
        if not await client.login(TEST_STUDENT_EMAIL, TEST_STUDENT_PASSWORD):
            print("Cannot proceed without login")
            return

        is_healthy = await client.check_health()
        print(
            f"\n✅ OpenCode Service: {'READY' if is_healthy else 'NOT AVAILABLE'}"
        )


async def run_all_examples():
    """Run all examples."""
    print("\n")
    print("╔════════════════════════════════════════════════════════════╗")
    print("║  OpenCode Content & Quiz Generation - Usage Examples      ║")
    print("╚════════════════════════════════════════════════════════════╝")

    try:
        await example_5_service_health()
        await example_4_get_available_topics()
        await example_1_basic_content_generation()
        await example_2_quiz_generation()
        await example_3_content_and_quiz()

        print("\n" + "=" * 60)
        print("✅ All examples completed!")
        print("=" * 60)

    except Exception as e:
        print(f"\n❌ Error running examples: {e}")


# ===========================
# SETUP & QUICK START GUIDE
# ===========================

SETUP_GUIDE = """
╔════════════════════════════════════════════════════════════╗
║       OpenCode Content & Quiz Generation Setup            ║
╚════════════════════════════════════════════════════════════╝

PREREQUISITES:
1. OpenCode Server running on http://localhost:4096
2. EduPulse Backend running on http://localhost:8000
3. Database with test user: student@edupulse.com

SETUP STEPS:

1. Install OpenCode (if not already installed):
   npm install -g opencode-ai
   OR
   brew install anomalyco/tap/opencode

2. Start OpenCode Server:
   opencode --server --port 4096
   
3. Install Python dependencies:
   pip install aiohttp

4. Run this test file:
   python test_opencode_integration.py

5. Check the output for:
   ✅ = Success
   ❌ = Error

API ENDPOINTS:

POST /api/opencode/content/generate
  Generate learning content for a topic
  
POST /api/opencode/quiz/generate
  Generate a quiz with questions
  
POST /api/opencode/content-and-quiz/generate
  Generate both content and quiz (concurrent)
  
GET /api/opencode/subjects/{subject_name}/topics
  Get available topics for a subject
  
GET /api/opencode/health
  Check OpenCode service status

CURL EXAMPLES:

# Generate Content
curl -X POST http://localhost:8000/api/opencode/content/generate \\
  -H "Authorization: Bearer YOUR_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{
    "subject_name": "Data Structures",
    "unit_number": 1,
    "topic": "Arrays and Linked Lists",
    "learning_preference": "mixed"
  }'

# Generate Quiz
curl -X POST "http://localhost:8000/api/opencode/quiz/generate?subject_name=Data Structures&unit_number=1&num_questions=5&difficulty_level=Intermediate" \\
  -H "Authorization: Bearer YOUR_TOKEN"

# Generate Content + Quiz
curl -X POST http://localhost:8000/api/opencode/content-and-quiz/generate \\
  -H "Authorization: Bearer YOUR_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{
    "subject_name": "Data Structures",
    "unit_number": 1,
    "topic": "Arrays and Linked Lists",
    "learning_preference": "mixed"
  }' \\
  -G -d "num_quiz_questions=5"
"""

if __name__ == "__main__":
    print(SETUP_GUIDE)
    print("\n\nRunning test examples...\n")
    
    # Run the examples
    asyncio.run(run_all_examples())
