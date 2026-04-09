import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/mark_models.dart';

class StudentMarksScreen extends StatefulWidget {
  final String? regNo;
  final bool hideScaffold;
  const StudentMarksScreen({super.key, this.regNo, this.hideScaffold = false});

  @override
  State<StudentMarksScreen> createState() => _StudentMarksScreenState();
}

class _StudentMarksScreenState extends State<StudentMarksScreen> {
  final ApiService _apiService = ApiService();
  List<Mark> _marks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _regNo;
  int? _selectedSemester;
  List<int> _availableSemesters = [];

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get reg_no: use provided one or fetch current user's
      if (widget.regNo != null) {
        _regNo = widget.regNo;
      } else {
        final user = await _apiService.getCurrentUser();
        _regNo = user.regNo;
      }

      if (_regNo == null) {
        throw Exception('Registration number not found');
      }

      // Fetch marks
      final marks = await _apiService.getStudentMarks(_regNo!, semester: _selectedSemester);
      
      // Extract available semesters
      final semesters = marks.map((m) => m.semester).toSet().toList()..sort();
      
      setState(() {
        _marks = marks;
        _availableSemesters = semesters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hideScaffold) {
      return _isLoading ? const Center(child: CircularProgressIndicator()) : _buildMarksContent();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.regNo != null ? 'Student Marks' : 'My Marks'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMarksContent(),
    );
  }

  Widget _buildMarksContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMarks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_availableSemesters.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Text(
                  'Filter by Semester:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    initialValue: _selectedSemester,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Semesters'),
                      ),
                      ..._availableSemesters.map((sem) => DropdownMenuItem(
                            value: sem,
                            child: Text('Semester $sem'),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSemester = value;
                      });
                      _loadMarks();
                    },
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _marks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No marks available',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _marks.length,
                  itemBuilder: (context, index) {
                    final mark = _marks[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Subject Header
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mark.subjectTitle,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        mark.subjectCode,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Sem ${mark.semester}',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            
                            // Internal Marks logic
                            if (mark.assignment1 != null || mark.slipTest1 != null || mark.cia1 != null) ...[
                              // Assignments
                              _buildSectionHeader('Assignments'),
                              const SizedBox(height: 8),
                              _buildMarkRow('Assignment 1', mark.assignment1),
                              _buildMarkRow('Assignment 2', mark.assignment2),
                              _buildMarkRow('Assignment 3', mark.assignment3),
                              _buildMarkRow('Assignment 4', mark.assignment4),
                              _buildMarkRow('Assignment 5', mark.assignment5),
                              
                              const SizedBox(height: 12),
                              
                              // Slip Tests
                              _buildSectionHeader('Slip Tests'),
                              const SizedBox(height: 8),
                              _buildMarkRow('Slip Test 1', mark.slipTest1),
                              _buildMarkRow('Slip Test 2', mark.slipTest2),
                              _buildMarkRow('Slip Test 3', mark.slipTest3),
                              _buildMarkRow('Slip Test 4', mark.slipTest4),
                              
                              const SizedBox(height: 12),
                              
                              // CIA & Model
                              _buildSectionHeader('Continuous Internal Assessment'),
                              const SizedBox(height: 8),
                              _buildMarkRow('CIA 1', mark.cia1),
                              _buildMarkRow('CIA 2', mark.cia2),
                              _buildMarkRow('Model Exam', mark.model),
                            ],
                            
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'University Grade',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (mark.universityResultGrade != null && mark.universityResultGrade!.trim().isNotEmpty)
                                        ? (mark.universityResultGrade == 'AREAR' || mark.universityResultGrade == 'U' 
                                            ? Colors.red.shade100 
                                            : Colors.green.shade100)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (mark.universityResultGrade != null && mark.universityResultGrade!.trim().isNotEmpty)
                                        ? mark.universityResultGrade!
                                        : 'Awaiting',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: (mark.universityResultGrade != null && mark.universityResultGrade!.trim().isNotEmpty)
                                          ? (mark.universityResultGrade == 'AREAR' || mark.universityResultGrade == 'U'
                                              ? Colors.red.shade800
                                              : Colors.green.shade800)
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildMarkRow(String label, int? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value != null ? value.toString() : '-',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
