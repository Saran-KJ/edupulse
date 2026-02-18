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
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummarySection(),
                            const SizedBox(height: 24),
                            _buildAttendanceList(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildSummarySection() {
    final stats = _calculateStats();
    final percentage = _calculatePercentage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Group records by month
    final groupedRecords = <String, List<Attendance>>{};
    
    for (var record in _attendanceRecords) {
      final parsedDate = DateTime.parse(record.date);
      final monthYear = DateFormat('MMMM yyyy').format(parsedDate);
      if (!groupedRecords.containsKey(monthYear)) {
        groupedRecords[monthYear] = [];
      }
      groupedRecords[monthYear]!.add(record);
    }

    // Sort months in descending order
    final sortedMonths = groupedRecords.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Records',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...sortedMonths.map((month) {
          final records = groupedRecords[month]!;
          // Sort records within month by date (descending)
          records.sort((a, b) {
            final dateA = DateTime.parse(a.date);
            final dateB = DateTime.parse(b.date);
            return dateB.compareTo(dateA);
          });
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  month,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              ...records.map((record) => _buildAttendanceCard(record)),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAttendanceCard(Attendance record) {
    final statusColor = _getStatusColor(record.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            record.status.toUpperCase() == 'PRESENT'
                ? Icons.check_circle
                : record.status.toUpperCase() == 'ABSENT'
                    ? Icons.cancel
                    : Icons.work,
            color: statusColor,
          ),
        ),
        title: Text(
          DateFormat('EEEE, MMM dd, yyyy').format(DateTime.parse(record.date)),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: record.reason != null && record.reason!.isNotEmpty
            ? Text(
                'Reason: ${record.reason}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: Text(
            record.status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
