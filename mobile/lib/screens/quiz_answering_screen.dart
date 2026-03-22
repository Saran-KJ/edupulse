import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

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
  
  late Map<int, String> answers; // question_id -> selected_answer
  int currentQuestionIndex = 0;
  bool isSubmitting = false;
  bool showResults = false;
  int correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    answers = {};
  }

  void selectAnswer(String option) {
    setState(() {
      answers[widget.quiz.questions[currentQuestionIndex].id] = option;
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

  void submitQuiz() async {
    if (answers.length != widget.quiz.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Convert answers map to string-keyed format
      Map<String, String> submissionAnswers = {};
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

      // Calculate results
      int correct = 0;
      for (var i = 0; i < widget.quiz.questions.length; i++) {
        final question = widget.quiz.questions[i];
        final userAnswer = answers[question.id];
        if (userAnswer == question.correctAnswer) {
          correct++;
        }
      }

      setState(() {
        isSubmitting = false;
        showResults = true;
        correctAnswers = correct;
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
    final isAnswered = answers.containsKey(question.id);

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
                      child: Text(
                        question.question,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Options
                  Text(
                    'Select an option:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  _buildOptionButton('A', question.optionA),
                  SizedBox(height: 8),
                  _buildOptionButton('B', question.optionB),
                  SizedBox(height: 8),
                  _buildOptionButton('C', question.optionC),
                  SizedBox(height: 8),
                  _buildOptionButton('D', question.optionD),
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

  Widget _buildOptionButton(String label, String text) {
    final question = widget.quiz.questions[currentQuestionIndex];
    final isSelected = answers[question.id] == label;

    return InkWell(
      onTap: () => selectAnswer(label),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
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
              child: Container(
                width: 200,
                height: 200,
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
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        isPassed ? 'Passed!' : 'Try Again',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
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
                    final isCorrect = userAnswer == question.correctAnswer;

                    return Card(
                      elevation: 1,
                      color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
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
                                    color:
                                        isCorrect ? Colors.green : Colors.red,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isCorrect
                                          ? Icons.check
                                          : Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Question ${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                              'Your answer: $userAnswer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                            if (!isCorrect)
                              Text(
                                'Correct answer: ${question.correctAnswer}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: 32),
            // Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text('Back to Home'),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
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
