import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/mark_models.dart';
import '../services/api_service.dart';
import 'learning_resources_screen.dart';
import 'learning_hub_screen.dart';
// import 'overall_learning_screen.dart';

class StudentRiskScreen extends StatefulWidget {
  const StudentRiskScreen({Key? key}) : super(key: key);

  @override
  _StudentRiskScreenState createState() => _StudentRiskScreenState();
}

class _StudentRiskScreenState extends State<StudentRiskScreen> {
  bool _isLoading = true;
  RiskPrediction? _overallRisk;
  List<Mark> _marks = [];
  String? _error;
  int? _selectedSemester;
  List<int> _availableSemesters = [];
  String? _isSelectingChoice;
  
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
        print("Error fetching ML risk: $e");
        // Fallback or ignore if ML service is down, effectively "Low" or "Unknown"
      }

      // Fetch Marks for Subject-wise Analysis, excluding Lab Papers
      final allMarks = await ApiService().getStudentMarks(user.regNo!, excludeLabs: true);
      
      final semesters = allMarks.map((m) => m.semester).toSet().toList()..sort();
      
      int? defaultSem;
      if (semesters.isNotEmpty) {
          defaultSem = semesters.last; // Current Semester
      }
      
      setState(() {
          _marks = allMarks;
          _availableSemesters = semesters;
          _selectedSemester = _selectedSemester ?? defaultSem;
      });
      
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Calculate Risk for a single subject based on available marks
  Map<String, dynamic> _calculateSubjectRisk(Mark mark) {
    // Internal 1 Components
    double st1 = (mark.slipTest1 ?? 0).toDouble();
    double st2 = (mark.slipTest2 ?? 0).toDouble();
    double a1 = (mark.assignment1 ?? 0).toDouble();
    double a2 = (mark.assignment2 ?? 0).toDouble();
    double cia1 = (mark.cia1 ?? 0).toDouble();
    
    // Check if Internal 1 has any data
    List<double> st1Vals = [st1, st2].where((v) => v > 0).toList();
    List<double> a1Vals = [a1, a2].where((v) => v > 0).toList();
    bool hasInt1 = st1Vals.isNotEmpty || a1Vals.isNotEmpty || cia1 > 0;
    
    double internal1Norm = 0;

    if (hasInt1) {
      double stAvg1 = st1Vals.isEmpty ? 0 : st1Vals.reduce((a, b) => a + b) / st1Vals.length;
      double assignAvg1 = a1Vals.isEmpty ? 0 : a1Vals.reduce((a, b) => a + b) / a1Vals.length;
      
      double internal1Raw = (0.3 * stAvg1) + (0.2 * assignAvg1) + (0.5 * cia1);
      
      // Dynamic max: ST=20, Assign=10, CIA=60 (scaled by coefficients)
      double maxInt1 = (st1Vals.isEmpty ? 0 : 0.3 * 20) + (a1Vals.isEmpty ? 0 : 0.2 * 10) + (cia1 > 0 ? 0.5 * 60 : 0);
      internal1Norm = maxInt1 > 0 ? (internal1Raw / maxInt1) * 100 : 0;
    }
    
    // Internal 2 Components
    double st3 = (mark.slipTest3 ?? 0).toDouble();
    double st4 = (mark.slipTest4 ?? 0).toDouble();
    double a3 = (mark.assignment3 ?? 0).toDouble();
    double a4 = (mark.assignment4 ?? 0).toDouble();
    double a5 = (mark.assignment5 ?? 0).toDouble();
    double cia2 = (mark.cia2 ?? 0).toDouble();
    double model = (mark.model ?? 0).toDouble();
    
    List<double> st2Vals = [st3, st4].where((v) => v > 0).toList();
    List<double> a2Vals = [a3, a4, a5].where((v) => v > 0).toList();
    bool hasInt2 = st2Vals.isNotEmpty || a2Vals.isNotEmpty || cia2 > 0 || model > 0;
    
    double internal2Norm = 0;

    if (hasInt2) {
      double stAvg2 = st2Vals.isEmpty ? 0 : st2Vals.reduce((a, b) => a + b) / st2Vals.length;
      double assignAvg2 = a2Vals.isEmpty ? 0 : a2Vals.reduce((a, b) => a + b) / a2Vals.length;
      
      double internal2Raw = (0.25 * stAvg2) + (0.15 * assignAvg2) + (0.3 * cia2) + (0.3 * model);
      
      // Dynamic max: ST=20, Assign=10, CIA=60, Model=100
      double maxInt2 = (st2Vals.isEmpty ? 0 : 0.25 * 20) + (a2Vals.isEmpty ? 0 : 0.15 * 10) + (cia2 > 0 ? 0.3 * 60 : 0) + (model > 0 ? 0.3 * 100 : 0);
      internal2Norm = maxInt2 > 0 ? (internal2Raw / maxInt2) * 100 : 0;
    }
    
    // Final Internal Calculation (Progressive)
    double finalInternal = 0;
    String basisText = "";

    if (hasInt1 && hasInt2) {
      finalInternal = (0.4 * internal1Norm) + (0.6 * internal2Norm);
      basisText = "Based on Full Data";
    } else if (hasInt1) {
      finalInternal = internal1Norm;
      basisText = "Based on Internal 1 only";
    } else if (hasInt2) {
      finalInternal = internal2Norm;
      basisText = "Based on Internal 2 only";
    } else {
      finalInternal = 0;
      basisText = "No Data";
    }
    
    // Heuristic Risk Level
    String status;
    Color color;
    
    if (finalInternal < 50) {
      status = "High Risk";
      color = Colors.red;
    } else if (finalInternal < 65) {
      status = "Medium Risk";
      color = Colors.orange;
    } else {
      status = "Low Risk";
      color = Colors.green;
    }
    
    return {
      "score": finalInternal,
      "status": status,
      "color": color,
      "basis": basisText,
      "int1_available": hasInt1,
      "int2_available": hasInt2
    };
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
                  "Overall ML Risk Level",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
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
              "Risk Score: ${_overallRisk!.riskScore.toStringAsFixed(1)}%",
              style: TextStyle(color: Colors.grey.shade600),
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
              )).toList(),
            ],
            
              // Global Learning Path Selection for LOW Risk students
              if (_overallRisk!.riskLevel == "Low") ...[
                const Divider(height: 32),
                const Text(
                  "Set Your Global Learning Path",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Focus on building professional skills and industry readiness.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: _buildPathOption(
                      "Skill Development",
                      Icons.psychology,
                      "Skill building",
                      _overallRisk!.learningPathPreference == "Skill Development",
                    ),
                  ),
                ),
              ]
          ],
        ),
      ),
    );
  }

  Widget _buildPathOption(String title, IconData icon, String subtitle, bool isSelected) {
    return InkWell(
      onTap: () => _handleGlobalPathSelection(title),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: _isSelectingChoice == title 
          ? const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(strokeWidth: 3),
            ))
          : Column(
              children: [
                Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 28),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue.shade700 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
      ),
    );
  }

  Future<void> _handleGlobalPathSelection(String choice) async {
    if (_isSelectingChoice != null) return;
    setState(() => _isSelectingChoice = choice);
    try {
      await ApiService().submitGlobalPathPreference(choice);
      await _loadRiskData();
      
      // Redirect to Learning Hub
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LearningHubScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSelectingChoice = null);
    }
  }

  Widget _buildSubjectList() {
    if (_marks.isEmpty) {
      return const Center(child: Text("No marks data found."));
    }
    
    // Filter marks logic
    List<Mark> filteredMarks = _marks;
    if (_selectedSemester != null) {
        filteredMarks = _marks.where((m) {
            // Include if it's the selected semester
            if (m.semester == _selectedSemester) return true;
            
            // If viewing the LATEST semester, also include any previous backlog (U or AREAR)
            bool isLatestSemester = _availableSemesters.isNotEmpty && _selectedSemester == _availableSemesters.last;
            if (isLatestSemester) {
                if (m.universityResultGrade == 'U' || m.universityResultGrade == 'AREAR' || m.universityResultGrade == 'F') {
                    return true;
                }
            }
            return false;
        }).toList();
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
          
        if (filteredMarks.isEmpty)
           const Padding(
             padding: EdgeInsets.all(32.0),
             child: Center(child: Text("No subjects match this filter.")),
           )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredMarks.length,
            itemBuilder: (context, index) {
              final mark = filteredMarks[index];
        final risk = _calculateSubjectRisk(mark);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              mark.subjectTitle, 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mark.subjectCode),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      "Proj. Internal: ${(risk['score'] as double).toStringAsFixed(1)}%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(
                        risk['basis'],
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                      ),
                    )
                  ],
                ),
              ],
            ),
            leading: CircleAvatar(
              backgroundColor: boxColor(risk['status']),
              child: Text(
                mark.subjectCode.substring(0, 2),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            trailing: Chip(
              label: Text(
                risk['status'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              backgroundColor: (risk['color'] as Color),
            ),
            children: [
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMarkSection("Internal 1", [
                      _buildMarkRow("Slip Test 1", mark.slipTest1),
                      _buildMarkRow("Slip Test 2", mark.slipTest2),
                      _buildMarkRow("Assignment 1", mark.assignment1),
                      _buildMarkRow("Assignment 2", mark.assignment2),
                      _buildMarkRow("CIA 1", mark.cia1, max: 60),
                    ]),
                    const SizedBox(height: 16),
                    _buildMarkSection("Internal 2", [
                      _buildMarkRow("Slip Test 3", mark.slipTest3),
                      _buildMarkRow("Slip Test 4", mark.slipTest4),
                      _buildMarkRow("Assignment 3", mark.assignment3),
                      _buildMarkRow("Assignment 4", mark.assignment4),
                      _buildMarkRow("Assignment 5", mark.assignment5),
                      _buildMarkRow("CIA 2", mark.cia2, max: 60),
                      _buildMarkRow("Model", mark.model, max: 100),
                    ]),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.menu_book),
                            label: const Text("Study Materials"),
                            onPressed: () {
                              String subjectRiskLevel;
                              switch (risk['status']) {
                                case 'High Risk': subjectRiskLevel = 'High'; break;
                                case 'Medium Risk': subjectRiskLevel = 'Medium'; break;
                                default: subjectRiskLevel = 'Low';
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LearningResourcesScreen(
                                    subjectCode: mark.subjectCode,
                                    subjectTitle: mark.subjectTitle,
                                    riskLevel: subjectRiskLevel,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    ),
      ],
    );
  }

  Widget _buildMarkSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        ...children
      ],
    );
  }

  Widget _buildMarkRow(String label, int? value, {int max = 0}) {
    // If value is 0 or null, we can treat it as pending/not entered for display
    bool isEntered = value != null && value > 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          isEntered 
            ? Text(
                value.toString(), 
                style: const TextStyle(fontWeight: FontWeight.w500)
              )
            : const Text(
                "-",
                style: TextStyle(color: Colors.grey)
              ),
        ],
      ),
    );
  }  
  Color boxColor (String status){
    if (status == "High Risk") return Colors.red;
    if (status == "Medium Risk") return Colors.orange;
    return Colors.green;
  }
}
