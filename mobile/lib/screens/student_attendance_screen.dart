import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/attendance_models.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String? regNo;
  final bool hideScaffold;
  const StudentAttendanceScreen({super.key, this.regNo, this.hideScaffold = false});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = true;
  String? _error;
  String? _regNo;
  int _selectedSemester = 1;
  
  DateTime _selectedDate = DateTime.now();
  int _selectedIndex = 0;

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
        // Fetch student profile to get the correct current semester
        try {
          final profileData = await ApiService().getStudentProfile360(_regNo!);
          if (profileData.containsKey('student')) {
            final studentSem = profileData['student']['semester'];
            setState(() {
              // If it's the first load, set selected semester to current
              if (_attendanceRecords.isEmpty) {
                _selectedSemester = studentSem;
              }
            });
          }
        } catch (e) {
          debugPrint('Error fetching student profile for semester: $e');
        }

        final records = await ApiService().getStudentAttendance(_regNo!, semester: _selectedSemester);
        
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
    if (widget.hideScaffold) {
      return _isLoading ? const Center(child: CircularProgressIndicator()) : _buildAttendanceContent();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBodyContent(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'DASHBOARD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'HISTORY',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights_rounded),
            label: 'INSIGHTS',
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildAttendanceContent();
      case 1:
        return _buildHistoryContent();
      case 2:
        return _buildInsightsContent();
      default:
        return _buildAttendanceContent();
    }
  }

  Widget _buildHistoryContent() {
    final groupedRecords = <String, List<Attendance>>{};
    for (var r in _attendanceRecords) {
      groupedRecords.putIfAbsent(r.date, () => []).add(r);
    }
    final sortedDates = groupedRecords.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        _buildHeader(),
        _buildSemesterSelector(),
        const SizedBox(height: 16),
        Expanded(
          child: sortedDates.isEmpty
              ? _buildNoRecordsView()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final records = groupedRecords[date]!;
                    final formattedDate = DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(date));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ),
                        ...records.map((r) => _buildTimelineItem(r)),
                        const Divider(height: 32),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInsightsContent() {
    final stats = _calculateStats();
    final percentage = _calculatePercentage();
    
    // Calculate subject-wise percentage
    final subjectStats = <String, Map<String, int>>{};
    for (var r in _attendanceRecords) {
      if (r.subjectCode == null) continue;
      final s = subjectStats.putIfAbsent(r.subjectCode!, () => {'present': 0, 'total': 0});
      s['total'] = s['total']! + 1;
      if (r.status.toUpperCase() == 'PRESENT' || r.status.toUpperCase() == 'OD') {
        s['present'] = s['present']! + 1;
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildSemesterSelector(),
          const SizedBox(height: 32),
          // Overall Chart
          Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Overall Attendance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: percentage >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniInsight(stats['present'].toString(), 'Present', Colors.green),
                    _buildMiniInsight(stats['absent'].toString(), 'Absent', Colors.red),
                    _buildMiniInsight(stats['od'].toString(), 'OD', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Subject-wise Breakdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subject-wise Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 16),
                ...subjectStats.entries.map((entry) {
                  final code = entry.key;
                  final p = (entry.value['present']! / entry.value['total']!) * 100;
                  return _buildSubjectRow(code, p);
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMiniInsight(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSubjectRow(String code, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: percentage >= 75 ? Colors.green : Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              color: percentage >= 75 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecordsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, color: Color(0xFF94A3B8), size: 64),
          SizedBox(height: 16),
          Text('No records found for this semester', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent() {
    if (_error != null) {
      return Center(
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
      );
    }

    if (_attendanceRecords.isEmpty && !_isLoading) {
      return Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.event_busy_rounded, size: 80, color: Colors.blue.shade300),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No attendance records found',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _loadAttendance,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SEMESTER $_selectedSemester VIEW',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Today, ${DateFormat('MMM dd').format(DateTime.now())}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildSemesterSelector(),
                      const SizedBox(width: 8),
                      _buildChangeMonthButton(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 32),
            _buildHourlySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Attendance Settings'),
                  content: const Text('Filter and display preferences will appear here in the next update.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
                  ],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.settings_rounded, color: Color(0xFF6366F1), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedSemester,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E293B)),
          items: List.generate(8, (index) => index + 1)
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      'Sem $s',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null && val != _selectedSemester) {
              setState(() {
                _selectedSemester = val;
              });
              _loadAttendance();
            }
          },
        ),
      ),
    );
  }

  Widget _buildChangeMonthButton() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: Color(0xFF1E293B), size: 18),
            SizedBox(width: 8),
            Text(
              'Change Month',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final stats = _calculateStats();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildStatCard(
            '${stats['present']}',
            'PRESENT',
            Icons.check_circle_rounded,
            const Color(0xFF10B981),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            '${stats['absent']}',
            'ABSENT',
            Icons.cancel_rounded,
            const Color(0xFFEF4444),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            '${stats['od']}',
            'ON DUTY',
            Icons.work_rounded,
            const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Hourly Attendance Record',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dailyRecords = _attendanceRecords.where((r) => r.date == today).toList();
    dailyRecords.sort((a, b) => a.period.compareTo(b.period));

    if (dailyRecords.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, color: Color(0xFF94A3B8), size: 48),
            SizedBox(height: 16),
            Text(
              'No records for today yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...dailyRecords.map((record) => _buildTimelineItem(record)),
        const SizedBox(height: 16),
        _buildPendingIndicator(7 - dailyRecords.length),
      ],
    );
  }

  Widget _buildTimelineItem(Attendance record) {
    final timeStr = record.time ?? _getTimeForPeriod(record.period);
    final statusColor = _getStatusColor(record.status);
    final statusLabel = record.status.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'START',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr.split(' ')[0],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  timeStr.split(' ')[1],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.subjectCode ?? 'General',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (record.time == null)
                    Text(
                      'Period ${record.period}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingIndicator(int pending) {
    if (pending <= 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pending_actions_rounded, color: Color(0xFF64748B), size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Remaining $pending hourly sessions pending tracking',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeForPeriod(int period) {
    switch (period) {
      case 1: return '08:00 AM';
      case 2: return '09:00 AM';
      case 3: return '10:00 AM';
      case 4: return '11:00 AM';
      case 5: return '12:00 PM';
      case 6: return '02:00 PM';
      case 7: return '03:00 PM';
      default: return '08:00 AM';
    }
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
      _loadAttendance();
    }
  }
}
