# Quiz Management System - Complete Analysis

## Executive Summary

The EduPulse system has two primary quiz flows:

1. **Scheduled Quizzes** - Faculty-initiated quizzes scheduled before formal assessments (CIA, Model Exam, Slip Tests)
2. **Practice/Generated Quizzes** - On-demand quizzes for early risk assessment and personalized learning

### Critical Issue Identified
The student dashboard endpoint `/api/students/me/pending-quizzes` has **subtle visibility issues** related to timezone handling and attempt filtering logic.

---

## 1. QUIZ SCHEDULING FLOW (Faculty Perspective)

### 1.1 API Endpoints

**Schedule Quiz**
```
POST /api/faculty/schedule-quiz
Endpoint: routes/faculty_routes.py:131-197
Authentication: Faculty role required
```

**Request Payload:**
```python
{
    "dept": "CSE",              # Department code
    "year": 3,                  # Year of study
    "section": "A",             # Section
    "subject_code": "19CS303",  # Subject code
    "subject_title": "Web Technologies",  # Subject title
    "unit_number": 1,           # Unit to test (1-5)
    "assessment_type": "CIA",   # Assessment type: Slip Test, CIA, Model Exam
    "deadline": "2025-03-22T17:30:00",  # ISO format deadline (local time)
    "start_time": "2025-03-22T15:00:00" # ISO format start time (optional, local time)
}
```

**Response:**
```json
{
    "id": 42,
    "message": "Quiz scheduled for CSE Year 3 A - Unit 1 before CIA",
    "start_time": "2025-03-22T15:00:00",
    "deadline": "2025-03-22T17:30:00"
}
```

**Get Faculty's Scheduled Quizzes**
```
GET /api/faculty/scheduled-quizzes
Endpoint: routes/faculty_routes.py:199-227
Returns: List of all quizzes scheduled by this faculty
```

**Close/Deactivate Quiz**
```
PUT /api/faculty/scheduled-quizzes/{quiz_id}/close
Endpoint: routes/faculty_routes.py:229-250
Deactivates a scheduled quiz (sets is_active=0)
```

### 1.2 Database Model: ScheduledQuiz

**Table:** `scheduled_quizzes`
**File:** models.py:427-443

```python
class ScheduledQuiz(Base):
    id                  # Primary key
    faculty_id          # Faculty who created it (NOT foreign key!)
    dept                # Department (CSE, ECE, etc.) - String
    year                # Year (1, 2, 3, 4)
    section             # Section (A, B, C, etc.)
    subject_code        # Subject code (e.g., 19CS303)
    subject_title       # Subject name
    unit_number         # Unit being tested
    assessment_type     # Slip Test, CIA, Model Exam
    start_time          # DateTime - When quiz becomes available (nullable)
    deadline            # DateTime - Hard deadline for submission
    is_active           # 0/1 flag (1=active, 0=closed)
    created_at          # Timestamp
```

### 1.3 Timezone Handling in Scheduling

**Issue Identified:** ⚠️ Inconsistent timezone conversion

In `faculty_routes.py:153-173`:
```python
# Faculty submits in local time (IST)
deadline_str = "2025-03-22T17:30:00"  # IST

# Backend tries to convert to UTC for storage
deadline = datetime.fromisoformat(deadline_str.replace('Z', ''))
if deadline.tzinfo is None:
    # Assume IST (+5:30) and convert to UTC
    deadline = deadline - timedelta(hours=5, minutes=30)
    # Result stored in DB: 2025-03-22T12:00:00 (UTC)
```

**Problem:** 
- Faculty times are submitted without timezone info
- Backend assumes IST and converts to UTC
- But later comparisons may use `datetime.now()` (local) instead of `datetime.utcnow()` (UTC)
- This causes visibility issues when comparing timestamps

---

## 2. QUIZ RETRIEVAL FLOW (Student Dashboard)

### 2.1 Student Dashboard Endpoint

**Get Pending Quizzes**
```
GET /api/students/me/pending-quizzes
Endpoint: routes/student_routes.py:538-609
Authentication: Student role required
Response: List of scheduled quizzes the student hasn't completed
```

### 2.2 Visibility Logic

**Location:** routes/student_routes.py:556-609

**Step 1: Match Student to Quizzes**
```python
# Filter quizzes by student's dept, year, section
scheduled_quizzes = db.query(models.ScheduledQuiz).filter(
    models.ScheduledQuiz.dept == student.dept,           # "CSE"
    models.ScheduledQuiz.year == student.year,           # 3
    models.ScheduledQuiz.section == student.section,     # "A"
    models.ScheduledQuiz.is_active == 1,                 # Not closed
    models.ScheduledQuiz.deadline > now,                 # Deadline in future
    or_(
        models.ScheduledQuiz.start_time <= now,          # Start time passed
        models.ScheduledQuiz.start_time.is_(None)        # OR no start_time
    )
).all()
```

**Step 2: Filter Out Completed Quizzes**
```python
# For each quiz, check if student attempted it
for quiz in scheduled_quizzes:
    has_attempted = db.query(models.StudentQuizAttempt).filter(
        models.StudentQuizAttempt.reg_no == student.reg_no,
        or_(
            # Priority 1: Exact scheduled quiz ID match
            models.StudentQuizAttempt.scheduled_quiz_id == quiz.id,
            
            # Priority 2: Backward compatibility - unit & subject match
            and_(
                models.StudentQuizAttempt.scheduled_quiz_id == None,
                models.StudentQuizAttempt.unit == quiz.unit_number,
                or_(
                    models.StudentQuizAttempt.subject == quiz.subject_code,
                    models.StudentQuizAttempt.subject == quiz.subject_title
                )
            )
        )
    ).first()
    
    if not has_attempted:
        # Add to pending quizzes
        pending.append(...)
```

### 2.3 Response Format

```json
[
  {
    "id": 42,
    "subject_code": "19CS303",
    "subject_title": "Web Technologies",
    "unit_number": 1,
    "assessment_type": "CIA",
    "start_time": "2025-03-22T09:30:00",
    "deadline": "2025-03-22T10:30:00",
    "faculty_id": 5
  }
]
```

---

## 3. QUIZ SUBMISSION & ATTEMPT TRACKING

### 3.1 Quiz Submission Endpoint

**Submit Quiz Answers**
```
POST /api/quiz/submit
Endpoint: routes/quiz_routes.py:118-207
Authentication: Student role required
```

**Request:**
```python
{
    "subject": "19CS303",      # Subject code or title
    "unit": 1,                 # Unit number
    "answers": {               # Question ID -> Selected Option
        "1": "A",
        "2": "B",
        "3": "C"
    },
    "risk_level": "LOW",       # Risk level (HIGH, MEDIUM, LOW)
    "scheduled_quiz_id": 42    # Optional: link to scheduled quiz
}
```

**Response:**
```json
{
    "total_questions": 20,
    "correct_answers": 18,
    "wrong_answers": 2,
    "score": 90.0,
    "status": "success",
    "risk_probability": 0.15
}
```

### 3.2 Database Model: StudentQuizAttempt

**Table:** `student_quiz_attempts`
**File:** models.py:400-413

```python
class StudentQuizAttempt(Base):
    id                      # Primary key
    reg_no                  # Student registration number
    subject                 # Subject code or title
    unit                    # Unit number
    total_questions         # Number of questions
    correct_answers         # Correct answer count
    wrong_answers           # Wrong answer count
    score                   # Score percentage (0-100)
    risk_level              # Risk level at attempt time
    attempted_at            # When student submitted
    scheduled_quiz_id       # FK to scheduled_quizzes.id (nullable)
    # nullable = practice quiz, not null = scheduled quiz
```

### 3.3 Submission Flow

1. **Validate Student Role** → Only students can submit
2. **Get Student Record** → Retrieve from dept-specific table
3. **Calculate Score** → Compare answers against `QuizQuestion.correct_answer`
4. **Save Attempt** → Create `StudentQuizAttempt` record
5. **Run ML Model** → Predict early risk using Logistic Regression
6. **Create Alert** → If risk is High, create `AcademicAlert`
7. **Update Learning Plan** → If score >= 80%, improve risk level in `PersonalizedLearningPlan`

---

## 4. QUIZ VISIBILITY CONDITIONS

### 4.1 Visibility Decision Tree

```
Is the quiz for the student's class?
  ├─ NO  → INVISIBLE
  └─ YES → Continue
       
Is the quiz active (is_active=1)?
  ├─ NO  → INVISIBLE
  └─ YES → Continue
       
Is the dea
