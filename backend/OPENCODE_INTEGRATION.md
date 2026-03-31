# OpenCode Content & Quiz Generation Integration

## Overview

This integration adds powerful AI-powered content and quiz generation capabilities to EduPulse using **OpenCode**, an open-source AI coding agent. Students can now generate comprehensive learning materials and quizzes on-demand for any subject and topic.

## Features

✨ **Smart Content Generation**
- Structured educational content with clear sections
- Learning objectives and key concepts
- Real-world examples and explanations
- Estimated reading time and difficulty levels
- Multiple learning preferences (text, visual, mixed)

✨ **AI-Generated Quizzes**
- Multiple-choice questions with validated JSON output
- Difficulty-based question generation
- Automatic answer explanations
- Consistency validation across questions

✨ **Concurrent Generation**
- Generate content and quiz simultaneously for efficiency
- Optimized for better response times
- Automatic error handling and retries

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     EduPulse Backend                         │
│  (FastAPI, PostgreSQL)                                       │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ↓
        ┌───────────────────┐
        │  OpenCode Routes  │
        │ (opencode_routes) │
        └────────┬──────────┘
                 │
                 ↓
    ┌────────────────────────────┐
    │  OpenCode Service Module   │
    │ (opencode_service.py)      │
    │                            │
    │ - generate_content()       │
    │ - generate_quiz()          │
    │ - generate_content_and_    │
    │   quiz()                   │
    └────────────┬───────────────┘
                 │
                 ↓
        ┌───────────────────┐
        │ OpenCode Server   │
        │ (localhost:4096)  │
        │                   │
        │ Uses Claude 3.5   │
        │ with JSON Schema  │
        │ Validation        │
        └───────────────────┘
```

## Installation

### 1. Install OpenCode

```bash
# Using npm
npm install -g opencode-ai

# Or using Homebrew (macOS)
brew install anomalyco/tap/opencode

# Or using Windows package managers
choco install opencode  # Windows Chocolatey
scoop install opencode  # Windows Scoop
```

### 2. Update Python Dependencies

The required dependencies are already in `requirements.txt`:
```
aiohttp==3.9.1
```

If not present, add it:
```bash
pip install aiohttp
```

### 3. Start OpenCode Server

In a separate terminal, start the OpenCode server:

```bash
# Start OpenCode server on port 4096
opencode --server --port 4096

# Or with custom configuration
opencode --server --port 4096 --hostname 127.0.0.1
```

You should see output like:
```
✓ Server running at http://localhost:4096
✓ Ready to accept connections
```

### 4. Verify Backend

Ensure your EduPulse backend is running:
```bash
cd backend
python main.py
```

## API Endpoints

### 1. Generate Learning Content

**Endpoint:** `POST /api/opencode/content/generate`

**Authentication:** Required (Student role)

**Request Body:**
```json
{
  "subject_name": "Data Structures",
  "unit_number": 1,
  "topic": "Arrays and Linked Lists",
  "learning_preference": "mixed"
}
```

**Parameters:**
- `subject_name` (string, required): Name of the subject
- `unit_number` (integer, required): Unit number (1-5)
- `topic` (string, required): Specific topic to cover
- `learning_preference` (string, optional): "text", "visual", or "mixed" (default: "text")

**Response:**
```json
{
  "subject": "Data Structures",
  "unit": 1,
  "topic": "Arrays and Linked Lists",
  "title": "Arrays and Linked Lists: Complete Guide",
  "introduction": "...",
  "sections": [
    {
      "title": "Section Title",
      "content": "Detailed content...",
      "key_points": ["Point 1", "Point 2"],
      "examples": ["Example 1", "Example 2"]
    }
  ],
  "summary": "...",
  "learning_objectives": ["Objective 1", "Objective 2"],
  "difficulty_level": "Intermediate",
  "estimated_read_time": "15 minutes"
}
```

### 2. Generate Quiz

**Endpoint:** `POST /api/opencode/quiz/generate`

**Authentication:** Required (Student role)

**Query Parameters:**
- `subject_name` (string, required): Subject name
- `unit_number` (integer, required): Unit number
- `num_questions` (integer, optional): Number of questions (1-20, default: 5)
- `difficulty_level` (string, optional): "Beginner", "Intermediate", or "Advanced" (default: "Intermediate")

**Example:**
```
POST /api/opencode/quiz/generate?subject_name=Data%20Structures&unit_number=1&num_questions=5&difficulty_level=Intermediate
```

**Response:**
```json
{
  "title": "Quiz: Data Structures Unit 1",
  "subject": "Data Structures",
  "unit": 1,
  "total_questions": 5,
  "questions": [
    {
      "question": "What is the time complexity of accessing an element in an array?",
      "options": ["O(1)", "O(n)", "O(log n)", "O(n²)"],
      "correct_answer": 0,
      "explanation": "Arrays have constant time access O(1) because we can directly access any element using its index.",
      "difficulty": "Beginner"
    }
  ],
  "difficulty_distribution": {
    "Beginner": 2,
    "Intermediate": 2,
    "Advanced": 1
  }
}
```

### 3. Generate Content + Quiz (Concurrent)

**Endpoint:** `POST /api/opencode/content-and-quiz/generate`

**Authentication:** Required (Student role)

**Request Body:**
```json
{
  "subject_name": "Data Structures",
  "unit_number": 1,
  "topic": "Arrays and Linked Lists",
  "learning_preference": "mixed"
}
```

**Query Parameters:**
- `num_quiz_questions` (integer, optional): Number of questions (1-20, default: 5)

**Response:**
```json
{
  "content": { /* ContentGenerationResponse */ },
  "quiz": { /* QuizGenerationResponse */ }
}
```

### 4. Get Available Topics

**Endpoint:** `GET /api/opencode/subjects/{subject_name}/topics`

**Authentication:** Required (Student role)

**Example:**
```
GET /api/opencode/subjects/Data%20Structures/topics
```

**Response:**
```json
{
  "subject": "Data Structures",
  "topics": [
    "Arrays and Linked Lists",
    "Stacks and Queues",
    "Trees and Graphs",
    "Sorting and Searching",
    "Hash Tables"
  ],
  "total_topics": 5
}
```

### 5. Service Health Check

**Endpoint:** `GET /api/opencode/health`

**Authentication:** Optional

**Response:**
```json
{
  "status": "healthy",
  "service": "opencode",
  "message": "OpenCode service is available"
}
```

## Usage Examples

### Using cURL

```bash
# 1. Login to get token
TOKEN=$(curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@edupulse.com",
    "password": "student123"
  }' | jq -r '.access_token')

# 2. Generate content
curl -X POST http://localhost:8000/api/opencode/content/generate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subject_name": "Data Structures",
    "unit_number": 1,
    "topic": "Arrays and Linked Lists",
    "learning_preference": "mixed"
  }' | jq .

# 3. Generate quiz
curl -X POST "http://localhost:8000/api/opencode/quiz/generate?subject_name=Data Structures&unit_number=1&num_questions=5" \
  -H "Authorization: Bearer $TOKEN" | jq .

# 4. Generate both
curl -X POST http://localhost:8000/api/opencode/content-and-quiz/generate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subject_name": "Data Structures",
    "unit_number": 1,
    "topic": "Arrays and Linked Lists"
  }' | jq .
```

### Using Python

```python
import asyncio
from test_opencode_integration import OpencodeTestClient

async def main():
    async with OpencodeTestClient() as client:
        # Login
        await client.login("student@edupulse.com", "student123")
        
        # Generate content
        content = await client.generate_content(
            subject_name="Data Structures",
            unit_number=1,
            topic="Arrays and Linked Lists",
            learning_preference="mixed"
        )
        
        # Generate quiz
        quiz = await client.generate_quiz(
            subject_name="Data Structures",
            unit_number=1,
            num_questions=5,
            difficulty_level="Intermediate"
        )
        
        # Generate both
        result = await client.generate_content_and_quiz(
            subject_name="Data Structures",
            unit_number=1,
            topic="Arrays and Linked Lists",
            num_quiz_questions=5
        )

asyncio.run(main())
```

### Using JavaScript/Node.js

```javascript
// Using fetch API
async function generateContent() {
  const token = localStorage.getItem('token');
  
  const response = await fetch(
    'http://localhost:8000/api/opencode/content/generate',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        subject_name: 'Data Structures',
        unit_number: 1,
        topic: 'Arrays and Linked Lists',
        learning_preference: 'mixed'
      })
    }
  );
  
  const content = await response.json();
  console.log(content);
}

generateContent();
```

## File Structure

```
backend/
├── opencode_service.py           # Core OpenCode integration
├── routes/
│   └── opencode_routes.py        # API endpoints
├── test_opencode_integration.py  # Test cases and examples
├── main.py                        # Updated with new routes
└── requirements.txt               # Added aiohttp
```

## Key Classes

### `GeneratedContent`
```python
class GeneratedContent(BaseModel):
    title: str
    introduction: str
    sections: List[ContentSection]
    summary: str
    learning_objectives: List[str]
    difficulty_level: str
    estimated_read_time: str
```

### `GeneratedQuiz`
```python
class GeneratedQuiz(BaseModel):
    title: str
    subject: str
    unit: int
    total_questions: int
    questions: List[QuizQuestion]
    difficulty_distribution: Dict[str, int]
```

### `QuizQuestion`
```python
class QuizQuestion(BaseModel):
    question: str
    options: List[str]
    correct_answer: int
    explanation: str
    difficulty: str
```

## Configuration

### Environment Variables

Add to your `.env` file if needed:

```env
# OpenCode Server Configuration
OPENCODE_SERVER_URL=http://localhost:4096
OPENCODE_TIMEOUT=30

# AI Model Configuration
OPENCODE_MODEL=anthropic/claude-3-5-sonnet-20241022
```

## Error Handling

The API provides helpful error messages:

```json
{
  "detail": "Failed to generate content. Please try again."
}
```

Common errors:
- `403 Forbidden`: Only students can access content/quiz generation
- `400 Bad Request`: Invalid parameters (e.g., num_questions > 20)
- `500 Internal Server Error`: OpenCode server not running or API error

## Performance

- **Content Generation**: ~10-30 seconds (depends on complexity)
- **Quiz Generation**: ~8-20 seconds for 5 questions
- **Concurrent (Content + Quiz)**: ~15-35 seconds (faster than sequential)

## Troubleshooting

### OpenCode Server Not Running

```bash
# Check if port 4096 is in use
netstat -an | grep 4096  # Unix/Linux/Mac
netstat -ano | findstr :4096  # Windows

# Start OpenCode server
opencode --server --port 4096
```

### Connection Timeout

Increase timeout in `opencode_service.py`:
```python
OPENCODE_TIMEOUT = 60  # Increase from 30 to 60 seconds
```

### No Token/Authentication Error

Make sure you're:
1. Sending a valid JWT token in the `Authorization` header
2. Using the format: `Bearer <token>`
3. Token hasn't expired

### Quiz Generation Returns Incomplete Data

Check OpenCode logs:
```bash
# Check OpenCode server output for errors
```

Try regenerating with fewer questions:
```
num_questions=3  # Instead of 20
```

## Future Enhancements

- [ ] Caching generated content and quizzes
- [ ] Custom prompt templates
- [ ] Support for multiple AI models
- [ ] Streaming responses for real-time content
- [ ] Content versioning and history
- [ ] Student feedback on content quality
- [ ] Analytics on generated content usage

## Contributing

To contribute to this feature:

1. Check `opencode_service.py` for the core logic
2. Add tests in `test_opencode_integration.py`
3. Update `opencode_routes.py` for new endpoints
4. Document changes in this README

## Support

For issues or questions:
- OpenCode: https://github.com/anomalyco/opencode
- EduPulse Issues: Check project issue tracker
- Discord: https://opencode.ai/discord

## License

This integration follows the same license as EduPulse and OpenCode.
