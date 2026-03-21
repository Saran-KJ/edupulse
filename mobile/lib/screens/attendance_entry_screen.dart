import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../models/attendance_models.dart';
import 'view_attendance_screen.dart';

class AttendanceEntryScreen extends StatefulWidget {
  final String dept;
  final int year;
  final String section;
  final String? subjectCode;
  final String? subjectTitle;

  const AttendanceEntryScreen({
    super.key,
    required this.dept,
    required this.year,
    required this.section,
    this.subjectCode,
    this.subjectTitle,
  });

  @override
  State<AttendanceEntryScreen> createState() => _AttendanceEntryScreenState();
}

class _AttendanceEntryScreenState extends State<AttendanceEntryScreen> {
  final _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  List<Student> _students = [];
  final Map<String, String> _attendanceStatus = {}; // regNo -> 'Present'/'Absent'
  final Map<String, String> _attendanceReasons = {}; // regNo -> Reason
  bool _isLoading = false;
  int _selectedPeriod = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final students = await _apiService.getStudents(
        dept: widget.dept,
        year: widget.year,
        section: widget.section,
      );
      
      setState(() {
        _students = students;
        // Initialize status to Present by default
        for (var s in students) {
          _attendanceStatus[s.regNo] = 'Present';
        }
      });

      await _loadAttendanceForDate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAttendanceForDate() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final attendance = await _apiService.getClassAttendance(
        widget.dept,
        widget.year,
        widget.section,
        dateStr,
        period: _selectedPeriod,
      );

      setState(() {
        // Reset to Present first
        for (var s in _students) {
          _attendanceStatus[s.regNo] = 'Present';
        }
        // Apply fetched status
        for (var a in attendance) {
          _attendanceStatus[a.regNo] = a.status;
          if (a.reason != null) {
            _attendanceReasons[a.regNo] = a.reason!;
          }
        }
      });
    } catch (e) {
      // If no attendance found, just keep defaults (Present)
      // Or if error, log it.

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAttendance() async {
    setState(() => _isLoading = true);
    try {
      // deptId logic removed as we use dept string now

      List<AttendanceInput> inputs = [];
      for (var s in _students) {
        inputs.add(AttendanceInput(
          regNo: s.regNo,
          studentName: s.name,
          status: _attendanceStatus[s.regNo] ?? 'Present',
          reason: _attendanceReasons[s.regNo],
        ));
      }

      await _apiService.submitBulkAttendance(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        year: widget.year,
        section: widget.section,
        dept: widget.dept,
        period: _selectedPeriod,
        subjectCode: widget.subjectCode,
        attendanceList: inputs,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendanceForDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter/View Attendance'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewAttendanceScreen()),
              );
            },
            icon: const Icon(Icons.visibility, color: Colors.white),
            label: const Text('View Attendance', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Period: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    DropdownButton<int>(
                      value: _selectedPeriod,
                      items: List.generate(7, (index) => index + 1)
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('$p', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null && val != _selectedPeriod) {
                          setState(() {
                            _selectedPeriod = val;
                          });
                          _loadAttendanceForDate();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Select Date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Student List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const Center(child: Text('No students found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final status = _attendanceStatus[student.regNo] ?? 'Present';
                          final isPresent = status == 'Present';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isPresent ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                                    child: Text(
                                      student.name[0],
                                      style: TextStyle(
                                        color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          student.regNo,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // P/A Buttons
                                  Row(
                                    children: [
                                      _buildStatusButton('P', 'Present', student.regNo),
                                      const SizedBox(width: 8),
                                      _buildStatusButton('OD', 'OD', student.regNo),
                                      const SizedBox(width: 8),
                                      _buildStatusButton('A', 'Absent', student.regNo),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Submit Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Attendance',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String label, String value, String regNo) {
    final isSelected = _attendanceStatus[regNo] == value;
    Color color;
    if (value == 'Present') {
      color = Colors.green;
    } else if (value == 'OD') {
      color = Colors.blue;
    } else {
      color = Colors.red;
    }
    
    return InkWell(
      onTap: () {
        if (value == 'OD') {
          _showReasonDialog(regNo);
        } else {
          setState(() {
            _attendanceStatus[regNo] = value;
            // Clear reason if not OD
            if (value != 'OD') {
              _attendanceReasons.remove(regNo);
            }
          });
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _showReasonDialog(String regNo) async {
    final controller = TextEditingController(text: _attendanceReasons[regNo] ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Reason for OD'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason / Activity Name',
            hintText: 'e.g., Sports Meet, Symposium',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _attendanceReasons[regNo] = controller.text;
                _attendanceStatus[regNo] = 'OD';
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
