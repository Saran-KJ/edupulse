# Flutter UI Enhancement Guide: Multi-Type Quiz Support

## Overview
This guide outlines how to enhance the Flutter quiz answering screen to support three question types:
- **MCQ (Multiple Choice Question)**: Single selection with radio buttons
- **MCS (Multiple Choice Selection)**: Multiple selection with checkboxes  
- **NAT (Numerical Answer Type)**: Numeric input field

## Current Implementation
The current `quiz_answering_screen.dart` only supports MCQ-style questions with 4 fixed options (A, B, C, D).

## Required Changes

### 1. Update Models (`models.dart`)

Add `questionType` to `QuizQuestion`:
```dart
class QuizQuestion {
  final int id;
  final String question;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String correctAnswer;
  final String difficulty;
  final String questionType; // NEW: 'MCQ', 'MCS', or 'NAT'
  final String? assessmentType; // NEW: 'SlipTest', 'CIA', 'ModelExam'
}
```

Update `QuizAttemptSubmission` to accept dynamic answers:
```dart
class QuizAttemptSubmission {
  final String subject;
  final int unit;
  final String riskLevel;
  final Map<String, dynamic> answers; // Changed from Map<String, String>
  // MCQ: answers[questionId] = "Option A"
  // MCS: answers[questionId] = ["Option A", "Option B"]
  // NAT: answers[questionId] = "3.14"
}
```

### 2. Update Quiz Answering Screen (`quiz_answering_screen.dart`)

#### 2.1 Change answer storage:
```dart
// OLD
late Map<int, String> answers;

// NEW  
late Map<int, dynamic> answers;
```

#### 2.2 Add question type-specific methods:
```dart
// MCQ: Select single answer
void selectMcqAnswer(String option) {
  final question = widget.quiz.questions[currentQuestionIndex];
  setState(() {
    answers[question.id] = option;
  });
}

// MCS: Toggle multiple answers
void toggleMcsAnswer(String option) {
  final question = widget.quiz.questions[currentQuestionIndex];
  setState(() {
    List<String> current = answers[question.id] ?? [];
    if (current.contains(option)) {
      current.remove(option);
    } else {
      current.add(option);
    }
    answers[question.id] = current;
  });
}

// NAT: Enter numeric value
void setNatAnswer(String value) {
  final question = widget.quiz.questions[currentQuestionIndex];
  setState(() {
    answers[question.id] = value;
  });
}
```

#### 2.3 Create question type-specific UI builders:
```dart
// MCQ Builder - Radio buttons for single selection
Widget _buildMcqQuestion(QuizQuestion q) {
  return Column(
    children: [
      Text('Select an option:', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 12),
      if (q.optionA != null) _buildMcqOption('Option A', q.optionA!),
      if (q.optionB != null) _buildMcqOption('Option B', q.optionB!),
      if (q.optionC != null) _buildMcqOption('Option C', q.optionC!),
      if (q.optionD != null) _buildMcqOption('Option D', q.optionD!),
    ],
  );
}

Widget _buildMcqOption(String label, String text) {
  final question = widget.quiz.questions[currentQuestionIndex];
  final isSelected = answers[question.id] == label;
  
  return InkWell(
    onTap: () => selectMcqAnswer(label),
    child: Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Radio<String>(
              value: label,
              groupValue: answers[question.id],
              onChanged: (value) => selectMcqAnswer(value!),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    ),
  );
}

// MCS Builder - Checkboxes for multiple selection
Widget _buildMcsQuestion(QuizQuestion q) {
  return Column(
    children: [
      Text('Select all correct options:', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 12),
      if (q.optionA != null) _buildMcsOption('Option A', q.optionA!),
      if (q.optionB != null) _buildMcsOption('Option B', q.optionB!),
      if (q.optionC != null) _buildMcsOption('Option C', q.optionC!),
      if (q.optionD != null) _buildMcsOption('Option D', q.optionD!),
    ],
  );
}

Widget _buildMcsOption(String label, String text) {
  final question = widget.quiz.questions[currentQuestionIndex];
  final selected = answers[question.id] ?? [];
  final isChecked = selected.contains(label);
  
  return InkWell(
    onTap: () => toggleMcsAnswer(label),
    child: Card(
      elevation: isChecked ? 4 : 1,
      color: isChecked ? Colors.blue.shade50 : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: isChecked,
              onChanged: (_) => toggleMcsAnswer(label),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    ),
  );
}

// NAT Builder - Number input field
Widget _buildNatQuestion(QuizQuestion q) {
  final question = widget.quiz.questions[currentQuestionIndex];
  final controller = TextEditingController(text: answers[question.id] ?? '');
  
  return Column(
    children: [
      Text('Enter the numeric answer:', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 16),
      TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'e.g., 3.14',
          suffixIcon: Icon(Icons.calculate),
        ),
        onChanged: (value) => setNatAnswer(value),
      ),
    ],
  );
}
```

#### 2.4 Update main question builder:
```dart
Widget _buildQuestionContent(QuizQuestion question) {
  switch (question.questionType.toUpperCase()) {
    case 'MCQ':
      return _buildMcqQuestion(question);
    case 'MCS':
      return _buildMcsQuestion(question);
    case 'NAT':
      return _buildNatQuestion(question);
    default:
      return _buildMcqQuestion(question);
  }
}
```

#### 2.5 Update build method:
Replace the fixed options display (lines 175-187) with:
```dart
SizedBox(height: 24),
_buildQuestionContent(question),
```

### 3. Test Cases

#### 3.1 Unit Tests (`test/quiz_answering_screen_test.dart`):
```dart
test('MCQ answer selection updates state', () async {
  // Create MCQ question
  // Verify selectMcqAnswer updates answers map
  // Verify UI shows selected radio button
});

test('MCS toggle adds/removes answers', () async {
  // Create MCS question
  // Verify toggleMcsAnswer adds option to list
  // Verify second toggle removes option
  // Verify UI shows checked boxes
});

test('NAT input stores numeric value', () async {
  // Create NAT question
  // Verify setNatAnswer stores value
  // Verify input field displays value
});

test('Quiz submission with mixed types', () async {
  // Create quiz with MCQ, MCS, NAT
  // Submit answers
  // Verify server receives correct format
});
```

#### 3.2 UI Tests:
- Test MCQ radio button selection and display
- Test MCS checkbox multi-select behavior
- Test NAT number input and validation
- Test navigation between different question types
- Test quiz submission with mixed types

### 4. API Integration

The backend already supports dynamic answers:
```python
# Backend accepts:
{
  "answers": {
    "1": "Option A",           # MCQ
    "2": ["Option A", "Option B"],  # MCS  
    "3": "3.14"               # NAT
  }
}

# Backend scoring handles each type
```

### 5. Implementation Checklist

- [ ] Update `QuizQuestion` model with `questionType` field
- [ ] Update `QuizAttemptSubmission` schema to accept `Map<String, dynamic>`
- [ ] Implement MCQ answer selection logic
- [ ] Implement MCS toggle answer logic
- [ ] Implement NAT numeric input logic
- [ ] Create MCQ UI builder
- [ ] Create MCS UI builder
- [ ] Create NAT UI builder
- [ ] Create main question type dispatcher
- [ ] Update build method to use new builders
- [ ] Handle question validation (ensure answer provided)
- [ ] Update answer review logic for different types
- [ ] Test all question types end-to-end
- [ ] Test quiz submission with mixed types
- [ ] Test edge cases (empty NAT, MCS partial selection)
- [ ] Add error handling for invalid numeric input

### 6. Optional Enhancements

- Add question type indicator badge (MCQ, MCS, NAT label)
- Add visual distinction between question types
- Add help tooltips explaining each question type
- Add numeric validation (range, decimals) for NAT
- Add keyboard helpers for NAT (calculator, suggestions)
- Add answer hints for MCS ("select all that apply")
- Add answer count indicator for MCS ("2/3 selected")

### 7. Backward Compatibility

The current implementation should remain backward compatible:
- Existing MCQ quizzes will have `questionType = "MCQ"` (default)
- Option fields will be nullable for NAT questions
- MCS questions will have all 4 options populated
- Answer format will be automatically converted to correct type

## Timeline Estimate
- Implementation: 4-6 hours
- Testing: 2-3 hours
- Debugging & refinement: 1-2 hours

**Total: 7-11 hours**

## Related Files
- Backend: `backend/scoring_service.py` (already implemented)
- Backend: `backend/routes/quiz_routes.py` (updated to use scoring service)
- Backend: Tests in `backend/test_submission_scoring.py` (passes all tests)
