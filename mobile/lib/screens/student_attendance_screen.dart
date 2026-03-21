import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/attendance_models.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String? regNo;
  const StudentAttendanceScreen({super.key, this.regNo});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = true;
  String? _error;
  String? _regNo;
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get reg_no: use provided one or fetch current user's
      if (widget.regNo != null) {
        _regNo = widget.regNo;
      } else {
        final user = await ApiService().getCurrentUser();
        _regNo = user.regNo;
      }

      if (_regNo != null) {
        final records = await ApiService().getStudentAttendance(_regNo!);
        
        setState(() {
          _attendanceRecords = records;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Registration number not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, int> _calculateStats() {
    int present = 0;
    int absent = 0;
    int od = 0;

    for (var record in _attendanceRecords) {
      switch (record.status.toUpperCase()) {
        case 'PRESENT':
          present++;
          break;
        case 'ABSENT':
          absent++;
          break;
        case 'OD':
          od++;
          break;
      }
    }

    return {
      'present': present,
      'absent': absent,
      'od': od,
      'total': _attendanceRecords.length,
    };
  }

  double _calculatePercentage() {
    final stats = _calculateStats();
    final total = stats['total']!;
    if (total == 0) return 0.0;
    
    // Count Present and OD as present
    final presentCount = stats['present']! + stats['od']!;
    return (presentCount / total) * 100;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return Colors.green;
      case 'ABSENT':
        return Colors.red;
      case 'OD':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.regNo != null ? 'Student Attendance' : 'My Attendance'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _attendanceRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No attendance records found',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAttendance,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDateSelector(context),
                                const SizedBox(height: 16),
                                _buildSummarySection(),
                                const SizedBox(height: 16),
                                _buildAttendanceList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildSummarySection() {
    final stats = _calculateStats();
    final percentage = _calculatePercentage();
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 600 ? 4 : 2;
    double childAspectRatio = screenWidth > 600 ? 1.8 : 1.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Summary',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              'Present',
              '${stats['present']}',
              Colors.green,
              Icons.check_circle_outline,
            ),
            _buildStatCard(
              'Absent',
              '${stats['absent']}',
              Colors.red,
              Icons.cancel_outlined,
            ),
            _buildStatCard(
              'On Duty',
              '${stats['od']}',
              Colors.orange,
              Icons.work_outline,
            ),
            _buildStatCard(
              'Percentage',
              '${percentage.toStringAsFixed(1)}%',
              percentage >= 75 ? Colors.green : Colors.red,
              Icons.percent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Change Month'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // The _buildAttendanceList method already groups and filters dynamically based on month viewing logic
    }
  }

  Widget _buildAttendanceList() {
    // Group records by month and filter by selected Month and Year
    final filteredRecords = _attendanceRecords.where((record) {
      final parsedDate = DateTime.parse(record.date);
      return parsedDate.month == _selectedDate.month && parsedDate.year == _selectedDate.year;
    }).toList();

    if(filteredRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No attendance records found for ${DateFormat('MMMM yyyy').format(_selectedDate)}',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Group by Date
    final Map<String, List<Attendance>> groupedByDate = {};
    for (var record in filteredRecords) {
      groupedByDate.putIfAbsent(record.date, () => []).add(record);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.blue.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ),
        ...sortedDates.map((dateStr) => _buildDailyAttendanceCard(dateStr, groupedByDate[dateStr]!)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDailyAttendanceCard(String dateStr, List<Attendance> dailyRecords) {
    // sort records by period ascending
    dailyRecords.sort((a, b) => a.period.compareTo(b.period));
    final parsedDate = DateTime.parse(dateStr);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMM dd, yyyy').format(parsedDate),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900),
                ),
              ],
            ),
          ),
          
          // List of periods
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: dailyRecords.map((record) {
                final statusColor = _getStatusColor(record.status);
                String subCode = record.subjectCode ?? '-';
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'P${record.period}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(width: 1, height: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        subCode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          record.status.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
