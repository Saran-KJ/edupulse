import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'learning_resources_screen.dart';

class EarlyRiskQuizScreen extends StatefulWidget {
  final String regNo;
  final String subjectCode;
  final int unitNumber;

  const EarlyRiskQuizScreen({
    required this.regNo,
    required this.subjectCode,
    required this.unitNumber,
  });

  @override
  _EarlyRiskQuizScreenState createState() => _EarlyRiskQuizScreenState();
}

class _EarlyRiskQuizScreenState extends State<EarlyRiskQuizScreen> {
  final ApiService apiService = ApiService();
  
  late TextEditingController subjectController;
  EarlyRiskAssessment? riskAssessment;
  Quiz? earlyRiskQuiz;
  bool isLoading = false;
  String? errorMessage;
  int currentQuestionIndex = 0;
  late Map<int, String> answers;
  bool showRiskAnalysis = true;
  bool quizSubmitted = false;
  int correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    subjectController = TextEditingController(text: widget.subjectCode);
    answers = {};
    _loadEarlyRiskAssessment();
  }

  @override
  void dispose() {
    subjectController.dispose();
    super.dispose();
  }

  void _loadEarlyRiskAssessment() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final assessment = await apiService.getEarlyRiskAssessment(
        regNo: widget.regNo,
        subjectCode: widget.subjectCode,
      );

      setState(() {
        riskAssessment = assessment;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  void _generateEarlyRiskQuiz() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final quizData = await apiService.generateEarlyRiskQuiz(
        regNo: widget.regNo,
        subjectCode: widget.subjectCode,
        unitNumber: widget.unitNumber,
      );

      final quiz = Quiz.fromJson(quizData);

      setState(() {
        earlyRiskQuiz = quiz;
        isLoading = false;
        showRiskAnalysis = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error generating quiz: ${e.toString()}';
      });
    }
  }

  void nextQuestion() {
    if (currentQuestionIndex < (earlyRiskQuiz?.questions.length ?? 0) - 1) {
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

  void submitQuiz() {
    if (answers.length != (earlyRiskQuiz?.questions.length ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    // Calculate results
    int correct = 0;
    for (var i = 0; i < (earlyRiskQuiz?.questions.length ?? 0); i++) {
      final question = earlyRiskQuiz!.questions[i];
      final userAnswer = answers[question.id];
      if (userAnswer == question.correctAnswer) {
        correct++;
      }
    }

    setState(() {
      quizSubmitted = true;
      correctAnswers = correct;
    });
  }

  void selectAnswer(String option) {
    setState(() {
      answers[earlyRiskQuiz!.questions[currentQuestionIndex].id] = option;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Early Risk Assessment'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            )
          : (showRiskAnalysis && riskAssessment != null)
              ? _buildRiskAnalysisScreen()
              : (quizSubmitted && earlyRiskQuiz != null)
                  ? _buildResultsScreen()
                  : (earlyRiskQuiz != null)
                      ? _buildQuizScreen()
                      : _buildErrorScreen(),
    );
  }

  Widget _buildRiskAnalysisScreen() {
    final risk = riskAssessment!;
    final probabilityPercent = (risk.probability * 100).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk Level Card
          Card(
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    risk.riskEmoji,
                    style: TextStyle(fontSize: 64),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Risk Level: ${risk.riskLevel}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(risk.riskLevel),
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$probabilityPercent% Risk Probability',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: risk.probability,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getRiskColor(risk.riskLevel),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Interpretation
          Card(
            elevation: 2,
            color: Colors.blue.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assessment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    risk.interpretation,
                    style: TextStyle(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Contributing Factors
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contributing Factors',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 12),
                  ...risk.features.entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatFeatureName(entry.key),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Recommendations
          Card(
            elevation: 2,
            color: Colors.green.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                  ),
                  SizedBox(height: 12),
                  ...risk.recommendations.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(entry.value),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Take Quiz Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _generateEarlyRiskQuiz,
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.quiz),
              label: Text(isLoading
                  ? 'Loading...'
                  : 'Take ${riskAssessment!.riskLevel} Risk Assessment Quiz'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _getRiskColor(riskAssessment!.riskLevel),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    final quiz = earlyRiskQuiz!;
    final question = quiz.questions[currentQuestionIndex];
    final isAnswered = _isQuestionAnswered(question.id);

    return Column(
      children: [
        LinearProgressIndicator(
          value: (currentQuestionIndex + 1) / quiz.questions.length,
          minHeight: 8,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentQuestionIndex + 1}/${quiz.questions.length}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text('${answers.length}/${quiz.questions.length}'),
                backgroundColor: isAnswered ? Colors.green.shade100 : Colors.orange.shade100,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                height: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: 12),
                        _buildQuestionTypeChip(question.questionType),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                _buildQuestionUI(question),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: currentQuestionIndex > 0 ? previousQuestion : null,
                icon: Icon(Icons.arrow_back),
                label: Text('Previous'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
              if (currentQuestionIndex < quiz.questions.length - 1)
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
                  onPressed: submitQuiz,
                  icon: Icon(Icons.check),
                  label: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isQuestionAnswered(int questionId) {
    if (!answers.containsKey(questionId)) return false;
    final answer = answers[questionId];
    if (answer == null) return false;
    return answer.isNotEmpty;
  }

  Widget _buildQuestionTypeChip(String type) {
    Color color = Colors.blue;
    if (type == 'MCS') color = Colors.purple;
    if (type == 'NAT') color = Colors.orange;

    return Chip(
      label: Text(type, style: TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

bool _isOptionEmpty(String? text) {
  if (text == null) return true;
  final clean = text.trim().toLowerCase();
  return clean.isEmpty || clean == "none" || clean == "null";
}

  Widget _buildQuestionUI(QuizQuestion question) {
    if (question.questionType == 'NAT') {
      return _buildNATUI(question);
    } else if (question.questionType == 'MCS') {
      return _buildMCSUI(question);
    } else {
      // If it's MCQ but has no options, fallback to NAT UI for robustness
      if (_isOptionEmpty(question.optionA) && _isOptionEmpty(question.optionB)) {
        return _buildNATUI(question);
      }
      return _buildMCQUI(question);
    }
  }

  Widget _buildMCQUI(QuizQuestion question) {
    return Column(
      children: ['A', 'B', 'C', 'D'].asMap().entries.map((entry) {
        final label = entry.value;
        final options = [
          question.optionA,
          question.optionB,
          question.optionC,
          question.optionD,
        ];
        final text = options[entry.key];
        if (text == null || text.isEmpty) return SizedBox.shrink();
        final isSelected = answers[question.id] == label;

        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => selectAnswer(label),
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
                      onChanged: (val) => selectAnswer(label),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text(text)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMCSUI(QuizQuestion question) {
    // Basic MCS support for Early Risk (simplified version of main quiz)
    final List<String> selected = (answers[question.id] ?? '').split(',').where((e) => e.isNotEmpty).toList();

    return Column(
      children: ['A', 'B', 'C', 'D'].asMap().entries.map((entry) {
        final label = entry.value;
        final options = [question.optionA, question.optionB, question.optionC, question.optionD];
        final text = options[entry.key];
        if (text == null || text.isEmpty) return SizedBox.shrink();
        final isSelected = selected.contains(label);

        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: CheckboxListTile(
            title: Text(text),
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selected.add(label);
                } else {
                  selected.remove(label);
                }
                answers[question.id] = selected.join(',');
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            tileColor: isSelected ? Colors.purple.shade50 : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNATUI(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter numeric answer:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'e.g. 7',
          ),
          onChanged: (val) {
            setState(() {
              answers[question.id] = val;
            });
          },
          controller: TextEditingController(text: answers[question.id] ?? '')..selection = TextSelection.fromPosition(TextPosition(offset: (answers[question.id] ?? '').length)),
        ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final quiz = earlyRiskQuiz!;
    final totalQuestions = quiz.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).toStringAsFixed(1);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 32),
            // Score Circle
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: correctAnswers >= (totalQuestions * 0.6).toInt()
                    ? Colors.green.shade100
                    : Colors.red.shade100,
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
                        color: correctAnswers >= (totalQuestions * 0.6).toInt()
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$correctAnswers/$totalQuestions correct',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Assessment Complete',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LearningResourcesScreen(
                        subjectCode: widget.subjectCode,
                        subjectTitle: widget.subjectCode, // Fallback title
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.menu_book),
                label: Text('View My Study Plan & Resources'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            errorMessage ?? 'Error loading assessment',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadEarlyRiskAssessment,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatFeatureName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
