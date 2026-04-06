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
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedSemester = 1;

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
        if (students.isNotEmpty) {
          _selectedSemester = students.first.semester;
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
        semester: _selectedSemester,
      );

      setState(() {
        // Reset to Present first
        for (var s in _students) {
          _attendanceStatus[s.regNo] = 'Present';
        }
        // Apply fetched status
        if (attendance.isNotEmpty) {
          for (var a in attendance) {
            _attendanceStatus[a.regNo] = a.status;
            if (a.reason != null) {
              _attendanceReasons[a.regNo] = a.reason!;
            }
          }
          // Warn the user with a dialog
          final dateStrFormatted = DateFormat('dd MMM').format(_selectedDate);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Attendance Exists'),
                ],
              ),
              content: Text(
                'Attendance records already exist for Period $_selectedPeriod on $dateStrFormatted. \n\nExisting data has been loaded for your review and editing.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
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

      final timeStr = _selectedTime.format(context);

      await _apiService.submitBulkAttendance(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        year: widget.year,
        semester: _selectedSemester,
        section: widget.section,
        dept: widget.dept,
        period: _selectedPeriod,
        time: timeStr,
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          widget.subjectCode != null ? 'Attendance: ${widget.subjectCode}' : 'Enter Attendance',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewAttendanceScreen()),
              );
            },
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'View Records',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildTopConfiguration(),
          _buildClassStatsBar(),
          Expanded(
            child: _isLoading && _students.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? _buildNoStudentsView()
                    : _buildStudentList(),
          ),
          _buildSubmitSection(),
        ],
      ),
    );
  }

  Widget _buildTopConfiguration() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedSemester,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                    items: List.generate(8, (index) => index + 1)
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('Sem $s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null && val != _selectedSemester) {
                        setState(() {
                          _selectedSemester = val;
                        });
                        _loadAttendanceForDate();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedPeriod,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                    items: List.generate(8, (index) => index + 1)
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text('Period $p', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassStatsBar() {
    int present = 0;
    int absent = 0;
    int od = 0;
    for (var s in _students) {
      final status = _attendanceStatus[s.regNo];
      if (status == 'Present') present++;
      else if (status == 'Absent') absent++;
      else if (status == 'OD') od++;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMiniStat('Total', '${_students.length}', Colors.grey),
          _buildMiniStat('Present', '$present', Colors.green),
          _buildMiniStat('Absent', '$absent', Colors.red),
          _buildMiniStat('OD', '$od', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color == Colors.grey ? const Color(0xFF1E293B) : color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildNoStudentsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No students found', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final status = _attendanceStatus[student.regNo] ?? 'Present';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  student.regNo.length > 2 ? student.regNo.substring(student.regNo.length - 3) : student.regNo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.regNo,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildSelectorButtons(student.regNo, status),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectorButtons(String regNo, String currentStatus) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusToggleItem('P', 'Present', currentStatus, regNo, Colors.green),
          _buildStatusToggleItem('OD', 'OD', currentStatus, regNo, const Color(0xFF3B82F6)),
          _buildStatusToggleItem('A', 'Absent', currentStatus, regNo, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildStatusToggleItem(String label, String value, String current, String regNo, Color color) {
    final isSelected = current == value;
    return InkWell(
      onTap: () {
        if (value == 'OD') {
          _showReasonDialog(regNo);
        } else {
          setState(() {
            _attendanceStatus[regNo] = value;
            if (value != 'OD') _attendanceReasons.remove(regNo);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? color : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Confirm & Submit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
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
