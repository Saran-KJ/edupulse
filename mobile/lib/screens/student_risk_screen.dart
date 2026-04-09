import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/mark_models.dart';
import '../services/api_service.dart';
import 'learning_resources_screen.dart';

// import 'overall_learning_screen.dart';

class StudentRiskScreen extends StatefulWidget {
  const StudentRiskScreen({super.key});

  @override
  StudentRiskScreenState createState() => StudentRiskScreenState();
}

class StudentRiskScreenState extends State<StudentRiskScreen> {
  bool _isLoading = true;
  RiskPrediction? _overallRisk;
  List<SubjectRisk> _subjectRisks = [];
  List<Mark> _allMarks = [];
  String? _error;
  int? _selectedSemester;
  List<int> _availableSemesters = [];
  
  @override
  void initState() {
    super.initState();
    _loadRiskData();
  }

  Future<void> _loadRiskData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService().getCurrentUser();
      if (user.regNo == null) throw Exception("Registration number not found");
      
      // Fetch Overall Risk from ML Model
      try {
        _overallRisk = await ApiService().predictRisk(user.regNo!);
      } catch (e) {
        debugPrint("Error fetching ML risk: $e");
      }

      // Fetch Consolidated Subject-wise Risk Analysis & Raw Marks
      final results = await Future.wait([
        ApiService().getSubjectRisks(user.regNo!),
        ApiService().getStudentMarks(user.regNo!),
      ]);
      
      final risks = results[0] as List<SubjectRisk>;
      _allMarks = results[1] as List<Mark>;
      
      final semesters = risks
          .where((r) => r.semester != null)
          .map((r) => r.semester!)
          .toSet()
          .toList()
          ..sort();
      
      int? defaultSem;
      if (semesters.isNotEmpty) {
          defaultSem = semesters.last; // Current Semester
      }
      
      setState(() {
          _subjectRisks = risks;
          _availableSemesters = semesters;
          _selectedSemester = _selectedSemester ?? defaultSem;
      });
      
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Analysis'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text('Error: $_error'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverallRiskCard(),
                  const SizedBox(height: 24),
                  const Text(
                    "Subject-wise Risk Analysis",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Based on current internal marks performance",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildSubjectList(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallRiskCard() {
    // If implementation failed or returns nothing yet
    if (_overallRisk == null) {
      return Card(
        color: Colors.grey.shade100,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Overall updated risk data is currently unavailable."),
        ),
      );
    }
    
    Color riskColor;
    switch (_overallRisk!.riskLevel) {
      case "High": riskColor = Colors.red; break;
      case "Medium": riskColor = Colors.orange; break;
      default: riskColor = Colors.green;
    }

    return Card(
      elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Academic Risk Level",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: riskColor),
                  ),
                  child: Text(
                    _overallRisk!.riskLevel.toUpperCase(),
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _overallRisk!.riskScore / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              "Performance Score: ${_overallRisk!.riskScore.toStringAsFixed(1)} / 100",
              style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_overallRisk!.reasons != null && _overallRisk!.reasons!.isNotEmpty) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Key Factors:",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
              ),
              const SizedBox(height: 8),
              ..._overallRisk!.reasons!.split(';').map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(child: Text(reason.trim())),
                  ],
                ),
              )),
            ],

          ],
        ),
      ),
    );
  }


  Widget _buildSubjectMarksDetail(SubjectRisk risk) {
    final marks = _allMarks.where((m) => m.subjectCode == risk.subjectCode).toList();
    if (marks.isEmpty) {
      return const Column(
        children: [
          Icon(Icons.assignment_late_outlined, color: Colors.orange, size: 32),
          SizedBox(height: 8),
          Text("Detailed mark records not found for this code."),
        ],
      );
    }
    final mark = marks.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Current Academic Status:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildMarkGroup("Assignments", [
                _buildMarkRow("Assignment 1", mark.assignment1),
                _buildMarkRow("Assignment 2", mark.assignment2),
                _buildMarkRow("Assignment 3", mark.assignment3),
                _buildMarkRow("Assignment 4", mark.assignment4),
                _buildMarkRow("Assignment 5", mark.assignment5),
              ]),
              const Divider(height: 24),
              _buildMarkGroup("Slip Tests", [
                _buildMarkRow("Slip Test 1", mark.slipTest1),
                _buildMarkRow("Slip Test 2", mark.slipTest2),
                _buildMarkRow("Slip Test 3", mark.slipTest3),
                _buildMarkRow("Slip Test 4", mark.slipTest4),
              ]),
              const Divider(height: 24),
              _buildMarkGroup("Internal Assessments", [
                _buildMarkRow("CIA 1", mark.cia1),
                _buildMarkRow("CIA 2", mark.cia2),
                _buildMarkRow("Model Exam", mark.model),
              ]),
              if (mark.universityResultGrade != null && mark.universityResultGrade!.isNotEmpty) ...[
                const Divider(height: 24),
                _buildMarkRow("University Grade", null, customValue: mark.universityResultGrade),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarkGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildSubjectList() {
    if (_subjectRisks.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text("No subjects found with activity (quizzes or marks)."),
      ));
    }
    
    List<SubjectRisk> filteredRisks = _subjectRisks;
    if (_selectedSemester != null) {
      filteredRisks = _subjectRisks.where((r) => r.semester == _selectedSemester).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_availableSemesters.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.blueGrey),
                const SizedBox(width: 8),
                const Text(
                  'Filter by Semester:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      value: _selectedSemester,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Semesters'),
                        ),
                        ..._availableSemesters.map((sem) {
                          return DropdownMenuItem(
                            value: sem,
                            child: Text('Semester $sem'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSemester = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
        if (filteredRisks.isEmpty)
           const Padding(
             padding: EdgeInsets.all(32.0),
             child: Center(child: Text("No subjects match this filter.")),
           )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredRisks.length,
            itemBuilder: (context, index) {
              final risk = filteredRisks[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              risk.subjectTitle, 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(risk.subjectCode),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      "Performance Score: ${(risk.score).toStringAsFixed(1)}%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300)
                      ),
                      child: Text(
                        risk.basis,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                      ),
                    )
                  ],
                ),
              ],
            ),
            leading: CircleAvatar(
              backgroundColor: boxColor(risk.riskLevel),
              child: Text(
                risk.subjectCode.substring(0, 2),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: boxColor(risk.riskLevel),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                risk.riskLevel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (!risk.hasMarks) ...[
                      const Icon(Icons.info_outline, color: Colors.blue, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        "Internal marks are not yet available for this subject.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "This risk analysis is ${risk.basis.toLowerCase()}.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ] else
                      _buildSubjectMarksDetail(risk),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.menu_book),
                        label: const Text("View Learning Resources"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LearningResourcesScreen(
                                subjectCode: risk.subjectCode,
                                subjectTitle: risk.subjectTitle,
                                riskLevel: risk.riskLevel,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
      ],
    );
  }

  Widget _buildMarkRow(String label, int? value, {String? customValue}) {
    // If value is 0 or null, we can treat it as pending/not entered for display
    bool isEntered = (value != null && value >= 0) || (customValue != null && customValue.isNotEmpty);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          if (customValue != null)
             Text(
                customValue, 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
              )
          else if (isEntered) 
            Text(
                value.toString(), 
                style: const TextStyle(fontWeight: FontWeight.w500)
              )
          else 
            const Text(
                "-",
                style: TextStyle(color: Colors.grey)
              ),
        ],
      ),
    );
  }  
  Color boxColor (String status){
    if (status == "High" || status == "High Risk") return Colors.red;
    if (status == "Medium" || status == "Medium Risk") return Colors.orange;
    return Colors.green;
  }
}
