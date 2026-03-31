import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final String subjectCode;
  final String subjectTitle;
  final int unitNumber;
  final String riskLevel;
  final int? scheduledQuizId;

  const QuizScreen({
    Key? key,
    required this.subjectCode,
    required this.subjectTitle,
    required this.unitNumber,
    required this.riskLevel,
    this.scheduledQuizId,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  Map<int, String> _userAnswers = {};
  String? _error;
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  Future<void> _fetchQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final quizData = await ApiService().getQuiz(
        subjectName: widget.subjectTitle,
        unitNumber: widget.unitNumber,
        riskLevel: widget.riskLevel,
      );
      final List<dynamic> questionsJson = quizData['quiz'];
      setState(() {
        _questions = questionsJson.map((q) => QuizQuestion.fromJson(q)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load quiz. Please check your connection and try again.";
        _isLoading = false;
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_userAnswers.length < _questions.length) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Unfinished Quiz"),
          content: Text("You have answered ${_userAnswers.length} out of ${_questions.length} questions. Do you want to submit anyway?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Continue Quiz")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Submit")),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);
    try {
      final submission = QuizAttemptSubmission(
        subject: widget.subjectTitle,
        unit: widget.unitNumber,
        riskLevel: widget.riskLevel,
        answers: _userAnswers.map((key, value) => MapEntry(key.toString(), value)),
        scheduledQuizId: widget.scheduledQuizId,
      );
      final result = await ApiService().submitQuiz(submission);
      setState(() {
        _result = result;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting quiz: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text("Generating your personalized quiz...", 
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              const SizedBox(height: 8),
              const Text("AI is crafting questions based on your risk level", 
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade300, size: 60),
                const SizedBox(height: 20),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _fetchQuiz, child: const Text("Retry")),
              ],
            ),
          ),
        ),
      );
    }

    if (_result != null) {
      return _buildResultView();
    }

    return _buildQuizView();
  }

  Widget _buildQuizView() {
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Unit ${widget.unitNumber} • ${widget.riskLevel} Level", 
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Text("${_currentIndex + 1}/${_questions.length}", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.blue.shade50,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            minHeight: 6,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      question.question,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                   Text(
                    _isOptionEmpty(question.optionA) 
                      ? "ENTER NUMERIC ANSWER" 
                      : "CHOOSE AN OPTION", 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                   const SizedBox(height: 16),
                   if (!_isOptionEmpty(question.optionA)) _buildOption(question.id, 'A', question.optionA!),
                   if (!_isOptionEmpty(question.optionB)) _buildOption(question.id, 'B', question.optionB!),
                   if (!_isOptionEmpty(question.optionC)) _buildOption(question.id, 'C', question.optionC!),
                   if (!_isOptionEmpty(question.optionD)) _buildOption(question.id, 'D', question.optionD!),
                   
                   // Fallback for NAT (Numerical Answer Type) or malformed MCQs
                   if (_isOptionEmpty(question.optionA) && _isOptionEmpty(question.optionB)) 
                     _buildNATInput(question.id),
                ],
              ),
            ),
          ),
          _buildNavigationFooter(),
        ],
      ),
    );
  }

  bool _isOptionEmpty(String? text) {
    if (text == null) return true;
    final clean = text.trim().toLowerCase();
    return clean.isEmpty || clean == "none" || clean == "null";
  }

  Widget _buildNATInput(int questionId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: "Type your numeric answer here...",
          border: InputBorder.none,
          icon: Icon(Icons.edit_note, color: Colors.blue.shade300),
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        onChanged: (value) {
          setState(() {
            _userAnswers[questionId] = value;
          });
        },
        controller: TextEditingController(text: _userAnswers[questionId] ?? "")
          ..selection = TextSelection.fromPosition(TextPosition(offset: (_userAnswers[questionId] ?? "").length)),
      ),
    );
  }

  Widget _buildOption(int questionId, String label, String text) {
    final isSelected = _userAnswers[questionId] == text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _userAnswers[questionId] = text;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(label, 
                    style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(text, 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue.shade900 : Colors.black87,
                  )),
              ),
              if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentIndex > 0)
            TextButton.icon(
              onPressed: _previousQuestion,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Previous"),
            )
          else
            const SizedBox(width: 100),
          
          if (_currentIndex < _questions.length - 1)
            ElevatedButton(
              onPressed: _userAnswers.containsKey(_questions[_currentIndex].id) ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Next"),
            )
          else
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Submit Quiz"),
            ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final score = _result!['score'] ?? 0.0;
    final correct = _result!['correct_answers'] ?? 0;
    final total = _result!['total_questions'] ?? 0;
    final isSuccess = score >= 80;

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isSuccess 
              ? [Colors.green.shade50, Colors.white]
              : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
              ),
              child: CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 12.0,
                percent: (score / 100).clamp(0.0, 1.0),
                center: Text("${score.toInt()}%", 
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                progressColor: isSuccess ? Colors.green : Colors.blue,
                backgroundColor: Colors.grey.shade100,
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ),
            const SizedBox(height: 40),
            Text(isSuccess ? "Excellent Work!" : "Good Attempt!", 
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("You secured $correct out of $total questions correctly.", 
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 32),
            if (isSuccess)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.green),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text("Your risk level has been updated thanks to your strong performance!", 
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Return to Learning Resources", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
