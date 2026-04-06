import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'learning_resources_screen.dart';

class QuizAnsweringScreen extends StatefulWidget {
  final Quiz quiz;
  final String subject;
  final int unit;
  final String riskLevel;

  const QuizAnsweringScreen({
    required this.quiz,
    required this.subject,
    required this.unit,
    required this.riskLevel,
  });

  @override
  _QuizAnsweringScreenState createState() => _QuizAnsweringScreenState();
}

class _QuizAnsweringScreenState extends State<QuizAnsweringScreen> {
  final ApiService apiService = ApiService();
  
  late Map<int, dynamic> answers; // question_id -> answer (String for MCQ, List for MCS, String for NAT)
  int currentQuestionIndex = 0;
  bool isSubmitting = false;
  bool showResults = false;
  int correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    answers = {};
  }

  void selectMCQAnswer(String option) {
    setState(() {
      answers[widget.quiz.questions[currentQuestionIndex].id] = option;
    });
  }

  void toggleMCSOption(String option) {
    setState(() {
      final questionId = widget.quiz.questions[currentQuestionIndex].id;
      final currentAnswers = answers[questionId] as List<String>? ?? [];
      
      if (currentAnswers.contains(option)) {
        currentAnswers.remove(option);
      } else {
        currentAnswers.add(option);
      }
      
      answers[questionId] = currentAnswers;
    });
  }

  void setNATAnswer(String value) {
    setState(() {
      answers[widget.quiz.questions[currentQuestionIndex].id] = value;
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  bool _isQuestionAnswered(int questionId) {
    if (!answers.containsKey(questionId)) return false;
    final answer = answers[questionId];
    
    if (answer is String) {
      return answer.isNotEmpty;
    } else if (answer is List) {
      return (answer as List).isNotEmpty;
    }
    return false;
  }

  void submitQuiz() async {
    if (answers.length != widget.quiz.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    // Validate that each question is actually answered
    for (final question in widget.quiz.questions) {
      if (!_isQuestionAnswered(question.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please answer all questions')),
        );
        return;
      }
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Convert answers map to string-keyed format
      Map<String, dynamic> submissionAnswers = {};
      answers.forEach((qId, answer) {
        submissionAnswers[qId.toString()] = answer;
      });

      final submission = QuizAttemptSubmission(
        subject: widget.subject,
        unit: widget.unit,
        riskLevel: widget.riskLevel,
        answers: submissionAnswers,
      );

      final result = await apiService.submitQuiz(submission);

      setState(() {
        isSubmitting = false;
        showResults = true;
        // Server calculates correct answers based on scoring service
        correctAnswers = result['correct_answers'] ?? 0;
      });
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting quiz: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showResults) {
      return _buildResultsScreen();
    }

    final question = widget.quiz.questions[currentQuestionIndex];
    final isAnswered = _isQuestionAnswered(question.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz - ${widget.subject}'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / widget.quiz.questions.length,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
          // Question counter
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text('${answers.length}/${widget.quiz.questions.length} answered'),
                  backgroundColor: isAnswered ? Colors.green.shade100 : Colors.orange.shade100,
                ),
              ],
            ),
          ),
          // Question Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Text
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.question,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.5,
                                ),
                          ),
                          SizedBox(height: 12),
                          _buildQuestionTypeChip(question.questionType),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Question Type Specific UI
                  _buildQuestionTypeUI(question),
                ],
              ),
            ),
          ),
          // Navigation Buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: currentQuestionIndex > 0 ? previousQuestion : null,
                  icon: Icon(Icons.arrow_back),
                  label: Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                ),
                if (currentQuestionIndex < widget.quiz.questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: nextQuestion,
                    icon: Icon(Icons.arrow_forward),
                    label: Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: isSubmitting ? null : submitQuiz,
                    icon: isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.check),
                    label: Text(isSubmitting ? 'Submitting...' : 'Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeChip(String questionType) {
    Color chipColor = Colors.blue;
    String label = questionType;

    if (questionType == 'MCQ') {
      chipColor = Colors.blue;
      label = 'MCQ - Single Answer';
    } else if (questionType == 'MCS') {
      chipColor = Colors.purple;
      label = 'MCS - Multiple Answers';
    } else if (questionType == 'NAT') {
      chipColor = Colors.orange;
      label = 'NAT - Numeric Answer';
    }

    return Chip(
      label: Text(label),
      backgroundColor: chipColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: chipColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQuestionTypeUI(QuizQuestion question) {
    if (question.questionType == 'MCQ') {
      return _buildMCQUI(question);
    } else if (question.questionType == 'MCS') {
      return _buildMCSUI(question);
    } else if (question.questionType == 'NAT') {
      return _buildNATUI(question);
    }
    
    // Default to MCQ
    return _buildMCQUI(question);
  }

  bool _isOptionEmpty(String? text) {
    if (text == null) return true;
    final clean = text.trim().toLowerCase();
    return clean.isEmpty || clean == "none" || clean == "null";
  }

  Widget _buildMCQUI(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isOptionEmpty(question.optionA) ? 'Enter numeric answer:' : 'Select one option:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        if (!_isOptionEmpty(question.optionA))
          _buildMCQOption('Option A', question.optionA!, question.id),
        if (!_isOptionEmpty(question.optionA)) SizedBox(height: 8),
        if (!_isOptionEmpty(question.optionB))
          _buildMCQOption('Option B', question.optionB!, question.id),
        if (!_isOptionEmpty(question.optionB)) SizedBox(height: 8),
        if (!_isOptionEmpty(question.optionC))
          _buildMCQOption('Option C', question.optionC!, question.id),
        if (!_isOptionEmpty(question.optionC)) SizedBox(height: 8),
        if (!_isOptionEmpty(question.optionD))
          _buildMCQOption('Option D', question.optionD!, question.id),
        
        // Fallback for when options are missing but it's marked as MCQ
        if (_isOptionEmpty(question.optionA) && _isOptionEmpty(question.optionB))
          _buildNATUI(question),
      ],
    );
  }

  Widget _buildMCQOption(String optionLabel, String optionText, int questionId) {
    final isSelected = answers[questionId] == optionLabel;

    return InkWell(
      onTap: () => selectMCQAnswer(optionLabel),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<String>(
                value: optionLabel,
                groupValue: answers[questionId],
                onChanged: (_) => selectMCQAnswer(optionLabel),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMCSUI(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select all correct options:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        if (question.optionA != null)
          _buildMCSOption('Option A', question.optionA!, question.id),
        if (question.optionA != null) SizedBox(height: 8),
        if (question.optionB != null)
          _buildMCSOption('Option B', question.optionB!, question.id),
        if (question.optionB != null) SizedBox(height: 8),
        if (question.optionC != null)
          _buildMCSOption('Option C', question.optionC!, question.id),
        if (question.optionC != null) SizedBox(height: 8),
        if (question.optionD != null)
          _buildMCSOption('Option D', question.optionD!, question.id),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.amber.shade800, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You must select all correct answers and no incorrect ones',
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMCSOption(String optionLabel, String optionText, int questionId) {
    final selectedOptions = answers[questionId] as List<String>? ?? [];
    final isSelected = selectedOptions.contains(optionLabel);

    return InkWell(
      onTap: () => toggleMCSOption(optionLabel),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected ? Colors.purple.shade50 : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => toggleMCSOption(optionLabel),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNATUI(QuizQuestion question) {
    final currentAnswer = answers[question.id] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the numeric answer:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        TextField(
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter a number (e.g., 3.14 or 1024)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (value) => setNATAnswer(value),
          controller: TextEditingController(text: currentAnswer),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade800, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Answer is evaluated with ±0.01 tolerance',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final totalQuestions = widget.quiz.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).toStringAsFixed(1);
    final isPassed = correctAnswers >= (totalQuestions * 0.6).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Results'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 32),
            // Result Card
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double size = MediaQuery.of(context).size.width * 0.4;
                  if (size > 220) size = 220;
                  if (size < 160) size = 160;

                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed ? Colors.green.shade100 : Colors.red.shade100,
                      boxShadow: [
                        BoxShadow(
                          color: (isPassed ? Colors.green : Colors.red).withOpacity(0.3),
                          spreadRadius: 8,
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: size * 0.3,
                              fontWeight: FontWeight.bold,
                              color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            isPassed ? 'Passed!' : 'Try Again',
                            style: TextStyle(
                              fontSize: size * 0.1,
                              fontWeight: FontWeight.bold,
                              color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            SizedBox(height: 32),
            // Statistics
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiz Statistics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: 16),
                      _buildStatRow('Correct Answers', '$correctAnswers/$totalQuestions'),
                      SizedBox(height: 12),
                      _buildStatRow(
                        'Wrong Answers',
                        '${totalQuestions - correctAnswers}/$totalQuestions',
                      ),
                      SizedBox(height: 12),
                      _buildStatRow('Score', '$percentage%'),
                      SizedBox(height: 12),
                      _buildStatRow('Difficulty', widget.riskLevel),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
            // Answer Review
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Answer Review',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 16),
                  ...widget.quiz.questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    final userAnswer = answers[question.id];

                    return _buildAnswerReviewCard(index + 1, question, userAnswer);
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: 32),
            // Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerReviewCard(int questionNumber, QuizQuestion question, dynamic userAnswer) {
    // For review purposes, we show what the user submitted
    // The server will have already calculated if it's correct
    final userAnswerText = _formatAnswerForDisplay(userAnswer);
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: Center(
                    child: Text(
                      '$questionNumber',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Question $questionNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(question.questionType),
                  backgroundColor: Colors.grey.shade300,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              question.question,
              style: TextStyle(height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Your answer: $userAnswerText',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAnswerForDisplay(dynamic answer) {
    if (answer == null) return 'Not answered';
    if (answer is String) return answer;
    if (answer is List) {
      return (answer as List).join(', ');
    }
    return answer.toString();
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
