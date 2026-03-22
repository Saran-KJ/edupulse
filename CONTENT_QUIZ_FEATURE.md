# Content & Quiz Generation Feature Documentation

## Overview
This document provides comprehensive information about the new AI-powered content and quiz generation features added to EduPulse.

## Features

### 1. **Learning Content Generation**
Generate comprehensive educational content for any subject and unit using AI (Google Gemini).

### 2. **Quiz Generation**
Automatically generate quiz questions based on subject units and difficulty levels.

### 3. **Combined Content + Quiz**
Generate both learning content and quizzes in a single API call.

---

## Backend API Endpoints

### Base URL
```
http://localhost:8000/api/content
```

### 1. Generate Learning Content
**POST** `/api/content/generate`

**Request Body:**
```json
{
  "subject_name": "Data Structures",
  "unit_number": 1,
  "topic": "Arrays and Linked Lists",
  "learning_preference": "text"  // "text", "visual", or "mixed"
}
```

**Response:**
```json
{
  "subject": "Data Structures",
  "unit": 1,
  "topic": "Arrays and Linked Lists",
  "title": "Understanding Arrays and Linked Lists",
  "introduction": "This unit covers...",
  "sections": [
    {
      "title": "Section 1: Arrays",
      "content": "Arrays are...",
      "key_points": ["Point 1", "Point 2"],
      "examples": ["Example 1", "Example 2"]
    }
  ],
  "summary": "In this unit, we learned...",
  "learning_objectives": ["Understand arrays", "Implement linked lists"],
  "difficulty_level": "Intermediate",
  "estimated_read_time": "15-20 minutes"
}
```

---

### 2. Generate Quiz Only
**GET** `/api/quiz/generate`

**Query Parameters:**
```
subject_name: "Data Structures"
unit_number: 1
risk_level: "MEDIUM"  // HIGH, MEDIUM, or LOW
```

**Response:**
```json
{
  "subject": "Data Structures",
  "unit": 1,
  "risk_level": "MEDIUM",
  "total_questions": 5,
  "quiz": [
    {
      "id": 1,
      "subject": "Data Structures",
      "unit": 1,
      "difficulty_level": "Intermediate",
      "question": "What is an array?",
      "option_a": "An ordered collection of elements",
      "option_b": "A tree structure",
      "option_c": "A linked list",
      "option_d": "A queue",
      "correct_answer": "A"
    }
  ]
}
```

---

### 3. Generate Content + Quiz Together
**POST** `/api/content/with-quiz?unit_number=1`

**Request Body:**
```json
{
  "subject_name": "Data Structures",
  "unit_number": 1,
  "topic": "Arrays and Linked Lists"
}
```

**Response:**
```json
{
  "content": {
    // Full LearningContent object (see above)
  },
  "quiz": {
    // Full Quiz object (see above)
  }
}
```

---

### 4. Get Available Topics
**GET** `/api/content/subjects/{subject_name}/topics`

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

---

### 5. Get Early Risk Assessment
**GET** `/api/predict/early-risk/{reg_no}/{subject_code}`

**Path Parameters:**
- `reg_no`: Student registration number (e.g., "CSE001")
- `subject_code`: Subject code (e.g., "CS101")

**Response:**
```json
{
  "student_id": "CSE001",
  "subject_code": "CS101",
  "risk_level": "HIGH",
  "probability": 0.82,
  "assessment_interpretation": "You are at HIGH risk. Your current performance metrics suggest you need immediate intervention...",
  "contributing_factors": {
    "quiz_score": 35.5,
    "attendance_percentage": 65.0,
    "internal_marks": 28,
    "backlog_count": 2,
    "learning_engagement": 4
  },
  "recommendations": [
    "Attend all remaining classes to improve attendance",
    "Increase study time focusing on fundamentals",
    "Seek help from instructors immediately",
    "Join study groups with peers"
  ]
}
```

---

### 6. Generate Early Risk Assessment Quiz
**POST** `/api/predict/early-risk-quiz`

**Request Body:**
```json
{
  "reg_no": "CSE001",
  "subject_code": "CS101",
  "unit_number": 1
}
```

**Response:**
```json
{
  "subject": "Data Structures",
  "unit": 1,
  "total_questions": 5,
  "risk_level": "HIGH",
  "difficulty_level": "Basic",
  "quiz": [
    {
      "id": 1,
      "subject": "Data Structures",
      "unit": 1,
      "difficulty_level": "Basic",
      "question": "What is an array?",
      "option_a": "An ordered collection of elements",
      "option_b": "A tree structure",
      "option_c": "A linked list",
      "option_d": "A queue",
      "correct_answer": "A",
      "is_early_risk_quiz": 1
    }
  ]
}
```

---

## Authentication
All endpoints require Bearer token authentication:
```
Authorization: Bearer <your_jwt_token>
```

---

## Flutter Integration

### 1. Using the ContentGenerationScreen

```dart
import 'package:your_app/screens/content_generation_screen.dart';

// Navigate to content generation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ContentGenerationScreen(),
  ),
);
```

### 2. Programmatic Content Generation

```dart
import 'package:your_app/services/api_service.dart';
import 'package:your_app/models/models.dart';

final apiService = ApiService();

try {
  final content = await apiService.generateContent(
    subjectName: 'Data Structures',
    unitNumber: 1,
    topic: 'Arrays',
    learningPreference: 'text',
  );
  
  print('Generated content: ${content.title}');
} catch (e) {
  print('Error: $e');
}
```

### 3. Using the Quiz Screen

```dart
import 'package:your_app/screens/quiz_answering_screen.dart';

// Navigate to quiz
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => QuizAnsweringScreen(
      quiz: quiz,
      subject: 'Data Structures',
      unit: 1,
      riskLevel: 'MEDIUM',
    ),
  ),
);
```

### 4. Generating Content with Quiz

```dart
final apiService = ApiService();

try {
  final contentWithQuiz = await apiService.generateContentWithQuiz(
    subjectName: 'Data Structures',
    unitNumber: 1,
    topic: 'Arrays',
  );
  
  // Display content
  showContentWidget(contentWithQuiz.content);
  
  // Then show quiz
  showQuizWidget(contentWithQuiz.quiz);
} catch (e) {
  print('Error: $e');
}
```

### 5. Using the Early Risk Assessment Screen

```dart
import 'package:your_app/screens/early_risk_quiz_screen.dart';

// Navigate to early risk assessment
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EarlyRiskQuizScreen(
      studentRegNo: 'CSE001',
      subjectCode: 'CS101',
    ),
  ),
);
```

### 6. Programmatic Early Risk Assessment

```dart
final apiService = ApiService();

try {
  // Get early risk assessment
  final assessment = await apiService.getEarlyRiskAssessment(
    regNo: 'CSE001',
    subjectCode: 'CS101',
  );
  
  print('Risk Level: ${assessment.riskLevel}');
  print('Probability: ${assessment.probability}');
  print('Recommendations: ${assessment.recommendations}');
  
  // Generate early risk quiz
  final quiz = await apiService.generateEarlyRiskQuiz(
    regNo: 'CSE001',
    subjectCode: 'CS101',
    unitNumber: 1,
  );
  
  // Quiz difficulty is automatically set based on risk level
  print('Quiz Difficulty: ${quiz.difficultyLevel}');
} catch (e) {
  print('Error: $e');
}
```

---

## Data Models

### LearningContent
```dart
class LearningContent {
  final String subject;
  final int unit;
  final String topic;
  final String title;
  final String introduction;
  final List<ContentSection> sections;
  final String summary;
  final List<String> learningObjectives;
  final String difficultyLevel;
  final String estimatedReadTime;
}
```

### ContentSection
```dart
class ContentSection {
  final String title;
  final String content;
  final List<String> keyPoints;
  final List<String>? examples;
}
```

### Quiz
```dart
class Quiz {
  final String subject;
  final int unit;
  final String riskLevel;
  final int totalQuestions;
  final List<QuizQuestion> questions;
}
```

### QuizQuestion
```dart
class QuizQuestion {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final String difficultyLevel;
  final int? isEarlyRiskQuiz;  // 1 if question is from early risk quiz, null otherwise
}
```

### EarlyRiskAssessment
```dart
class EarlyRiskAssessment {
  final String studentId;
  final String subjectCode;
  final String riskLevel;  // "LOW", "MEDIUM", or "HIGH"
  final double probability;  // 0.0 to 1.0
  final String assessmentInterpretation;
  final Map<String, dynamic> contributingFactors;  // quiz_score, attendance_percentage, etc.
  final List<String> recommendations;
  
  // Helper methods
  String getRiskColor();  // Returns color hex for risk level
  String getRiskEmoji();  // Returns emoji (😊, 😐, 😟) for risk level
}
```

---

## Backend Implementation Details

### Files Added/Modified

#### New Files:
1. **`backend/routes/content_routes.py`** - Content generation API endpoints
2. **`mobile/lib/screens/content_generation_screen.dart`** - Flutter UI for content display
3. **`mobile/lib/screens/quiz_answering_screen.dart`** - Flutter UI for quiz answering
4. **`mobile/lib/screens/early_risk_quiz_screen.dart`** - Flutter UI for early risk assessment and quiz

#### Modified Files:
1. **`backend/gemini_service.py`** - Added `generate_learning_content()` function
2. **`backend/schemas.py`** - Added content-related and early risk Pydantic schemas
3. **`backend/main.py`** - Registered content routes
4. **`backend/models.py`** - Added `is_early_risk_quiz` column to QuizQuestion table
5. **`backend/routes/prediction_routes.py`** - Added early risk quiz generation endpoints
6. **`mobile/lib/models/models.dart`** - Added content, quiz, and EarlyRiskAssessment model classes
7. **`mobile/lib/services/api_service.dart`** - Added content and early risk API methods

### Gemini Integration

Content generation uses Google Gemini API with JSON output:

```python
def generate_learning_content(subject_name: str, unit_number: int, topic: str, risk_level: str = "MEDIUM") -> dict:
    """
    Calls Gemini API with structured prompt to generate educational content.
    Returns JSON with sections, key points, examples, and summary.
    """
```

---

## Usage Examples

### Example 1: Generate Content for Data Structures Unit 1

**cURL:**
```bash
curl -X POST http://localhost:8000/api/content/generate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subject_name": "Data Structures",
    "unit_number": 1,
    "topic": "Arrays and Linked Lists",
    "learning_preference": "text"
  }'
```

**Python:**
```python
import requests

headers = {
    "Authorization": "Bearer YOUR_TOKEN",
    "Content-Type": "application/json"
}

data = {
    "subject_name": "Data Structures",
    "unit_number": 1,
    "topic": "Arrays and Linked Lists",
    "learning_preference": "text"
}

response = requests.post(
    "http://localhost:8000/api/content/generate",
    headers=headers,
    json=data
)

content = response.json()
print(content['title'])
```

---

### Example 2: Generate Quiz

**cURL:**
```bash
curl -X GET "http://localhost:8000/api/quiz/generate?subject_name=Data%20Structures&unit_number=1&risk_level=MEDIUM" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### Example 3: Submit Quiz Answers

**cURL:**
```bash
curl -X POST http://localhost:8000/api/quiz/submit-attempt \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "Data Structures",
    "unit": 1,
    "risk_level": "MEDIUM",
    "answers": {
      "1": "A",
      "2": "B",
      "3": "C",
      "4": "A",
      "5": "D"
    }
  }'
```

---

### Example 4: Get Early Risk Assessment

**cURL:**
```bash
curl -X GET "http://localhost:8000/api/predict/early-risk/CSE001/CS101" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "student_id": "CSE001",
  "subject_code": "CS101",
  "risk_level": "HIGH",
  "probability": 0.82,
  "assessment_interpretation": "You are at HIGH risk. Your current performance metrics...",
  "contributing_factors": {
    "quiz_score": 35.5,
    "attendance_percentage": 65.0,
    "internal_marks": 28,
    "backlog_count": 2,
    "learning_engagement": 4
  },
  "recommendations": [
    "Attend all remaining classes",
    "Increase study time on fundamentals",
    "Seek help from instructors immediately",
    "Join study groups"
  ]
}
```

---

### Example 5: Generate Early Risk Assessment Quiz

**cURL:**
```bash
curl -X POST http://localhost:8000/api/predict/early-risk-quiz \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reg_no": "CSE001",
    "subject_code": "CS101",
    "unit_number": 1
  }'
```

**Python:**
```python
import requests

headers = {
    "Authorization": "Bearer YOUR_TOKEN",
    "Content-Type": "application/json"
}

data = {
    "reg_no": "CSE001",
    "subject_code": "CS101",
    "unit_number": 1
}

response = requests.post(
    "http://localhost:8000/api/predict/early-risk-quiz",
    headers=headers,
    json=data
)

quiz = response.json()
print(f"Risk Level: {quiz['risk_level']}")
print(f"Difficulty: {quiz['difficulty_level']}")
print(f"Questions: {quiz['total_questions']}")
```

---

## Error Handling

### Common Errors

1. **401 Unauthorized**
   - Token not provided or expired
   - Solution: Re-authenticate and get new token

2. **403 Forbidden**
   - Only students can access these endpoints
   - Solution: Ensure you're logged in as a student

3. **500 Internal Server Error**
   - AI service failure (Gemini API issue)
   - Solution: Check API key, retry request

### Error Response Format
```json
{
  "detail": "Error message explaining what went wrong"
}
```

---

## Performance Considerations

1. **Content Generation**: Takes 10-30 seconds depending on Gemini response time
2. **Quiz Generation**: Takes 5-15 seconds
3. **Caching**: Database stores generated quizzes to reduce API calls
4. **Rate Limiting**: Implement rate limiting for production

---

## Future Enhancements

1. **Video Content Generation**: Generate video recommendations
2. **Interactive Quizzes**: Add timer, shuffle options, review mode
3. **Progress Tracking**: Track student's content viewing and quiz attempts
4. **Spaced Repetition**: Recommend content based on learning schedule
5. **Custom Content**: Allow teachers to customize generated content
6. **Multiple Languages**: Support Tamil, Telugu, Kannada, Hindi
7. **Offline Mode**: Cache content for offline access
8. **Risk Trend Analysis**: Show historical risk level trends for students
9. **Intervention Automation**: Auto-notify instructors when student reaches HIGH risk
10. **Content Recommendations**: Suggest specific content based on risk factors

---

## Testing

### Manual Testing Checklist

- [ ] Generate content for different subjects
- [ ] Verify content has all required fields
- [ ] Generate quizzes with different risk levels
- [ ] Answer quiz questions and verify scoring
- [ ] Test content + quiz generation
- [ ] Verify error handling for missing fields
- [ ] Check authentication requirements
- [ ] Test database storage of generated content
- [ ] Get early risk assessment for a student
- [ ] Verify risk level matches ML prediction
- [ ] Generate early risk quiz and verify difficulty
- [ ] Verify quiz questions marked as early risk quiz
- [ ] Test early risk assessment recommendations based on risk level
- [ ] Verify contributing factors display correctly

### API Testing

Use Postman or similar tools with:
1. Set Bearer token in Authorization header
2. Use examples provided above
3. Verify response JSON schema matches documentation

---

## Support & Troubleshooting

### Issue: "Failed to generate content"
- Check internet connection
- Verify Gemini API key is valid
- Check API quotas

### Issue: "Only students can access content generation"
- Ensure logged-in user role is "student"
- Check token validity

### Issue: Flutter app crashes when generating content
- Check API_URL configuration
- Verify token is properly loaded from SharedPreferences
- Check exception handling in try-catch blocks

---

## Contact & Contributors

For issues, feature requests, or contributions, please refer to the main EduPulse README.

---

**Last Updated**: March 2026  
**Version**: 1.0.0  
**Status**: Production Ready
