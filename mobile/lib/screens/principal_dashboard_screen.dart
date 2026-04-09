import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/responsive_layout.dart';
import '../config/app_theme.dart';
import '../widgets/main_scaffold.dart';
import 'role_selection_screen.dart';

class PrincipalDashboardScreen extends StatefulWidget {
  const PrincipalDashboardScreen({super.key});

  @override
  State<PrincipalDashboardScreen> createState() => _PrincipalDashboardScreenState();
}

class _PrincipalDashboardScreenState extends State<PrincipalDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  CollegeSummaryResponse? _collegeSummary;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final summary = await _apiService.getCollegeSummary();
      if (mounted) {
        setState(() {
          _collegeSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _logout() async {
    await _apiService.clearToken();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Principal Dashboard',
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavDestination(icon: Icons.insights_rounded, label: 'Institution Pulse'),
        NavDestination(icon: Icons.list_alt_rounded, label: 'Department Reports'),
      ],
      onLogout: _logout,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: _buildSelectedBody(),
            ),
    );
  }

  Widget _buildSelectedBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewBody();
      case 1:
        return _buildDepartmentReportsBody();
      default:
        return _buildOverviewBody();
    }
  }

  Widget _buildOverviewBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadershipHeader(),
            const SizedBox(height: 32),
            const SectionHeader(
              title: 'Institutional Vital Signs',
              icon: Icons.analytics_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            _buildInstitutionalStats(),
            const SizedBox(height: 32),
            const SectionHeader(
              title: 'Department Performance Matrix',
              icon: Icons.domain_rounded,
              color: AppColors.accent,
            ),
            const SizedBox(height: 16),
            _buildDepartmentMatrix(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentReportsBody() {
     return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(
                        'COLLEGE-WIDE REPORTS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        'Departmental Performance',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                   ],
                 ),
                 ElevatedButton.icon(
                   onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Generating PDF Report...'), duration: Duration(seconds: 1)),
                      );
                   },
                   icon: const Icon(Icons.download_rounded),
                   label: const Text('Export PDF'),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.black,
                     foregroundColor: Colors.white,
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 32),
             _buildDetailedReportTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReportTable() {
     final depts = _collegeSummary?.departmentSummaries ?? [];
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.subtle,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: DataTable(
        columnSpacing: 12,
        headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13),
        dataRowMaxHeight: 70,
        columns: const [
          DataColumn(label: Text('DEPT')),
          DataColumn(label: Text('STUDENTS')),
          DataColumn(label: Text('ATTENDANCE')),
          DataColumn(label: Text('RISK')),
          DataColumn(label: Text('MASTERY')),
        ],
        rows: depts.map((dept) {
          return DataRow(
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(dept.deptCode, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ),
              DataCell(Text('${dept.studentCount}')),
              DataCell(
                 Row(
                   children: [
                     Icon(
                       dept.avgAttendance >= 80 ? Icons.trending_up : Icons.trending_down,
                       color: dept.avgAttendance >= 80 ? AppColors.success : AppColors.error,
                       size: 14,
                     ),
                     const SizedBox(width: 4),
                     Text('${dept.avgAttendance}%'),
                   ],
                 ),
              ),
              DataCell(
                Text(
                  '${dept.atRiskCount}', 
                  style: TextStyle(
                    color: dept.atRiskCount > 0 ? AppColors.error : AppColors.textSecondary,
                    fontWeight: dept.atRiskCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                     color: AppColors.accentWarm.withValues(alpha: 0.1),
                     shape: BoxShape.circle,
                  ),
                  child: Text('${dept.highPerformerCount}', style: const TextStyle(color: AppColors.accentWarm, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeadershipHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INSTITUTIONAL COMMAND',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueAccent.shade100,
                      letterSpacing: 2.5,
                    ),
                  ),
                  Text(
                        'Welcome, Principal',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildQuickMetric('STUDENTS', '${_collegeSummary?.totalStudents ?? 0}'),
              const SizedBox(width: 24),
              _buildQuickMetric('DEPARTMENTS', '${_collegeSummary?.departmentSummaries.length ?? 0}'),
              const SizedBox(width: 24),
              _buildQuickMetric('AVG. ATTENDANCE', '${_collegeSummary?.avgCollegeAttendance ?? 0}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInstitutionalStats() {
    final stats = [
      {
        'title': 'Overall Attendance',
        'value': '${_collegeSummary?.avgCollegeAttendance ?? 0}%',
        'icon': Icons.calendar_today_rounded,
        'color': const Color(0xFF4CAF50),
      },
      {
        'title': 'Institutional Risk',
        'value': '${_collegeSummary?.totalAtRisk ?? 0}',
        'subtitle': 'At-Risk Students',
        'icon': Icons.warning_rounded,
        'color': const Color(0xFFF44336),
      },
      {
        'title': 'High Performers',
        'value': '${_collegeSummary?.totalHighPerformers ?? 0}',
        'subtitle': 'Mastery Achieved',
        'icon': Icons.stars_rounded,
        'color': const Color(0xFFFFC107),
      },
      {
        'title': 'Total Activities',
        'value': '${_collegeSummary?.totalActivities ?? 0}',
        'subtitle': 'Institutional Pulse',
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFF2196F3),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveBreakpoints.isDesktop(context) ? 4 : (ResponsiveBreakpoints.isTablet(context) ? 2 : 1),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.subtle,
            border: Border.all(color: (stat['color'] as Color).withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (stat['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 24),
                  ),
                  Text(
                    stat['subtitle']?.toString() ?? 'Institutional',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat['value'] as String,
                    style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    stat['title'] as String,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDepartmentMatrix() {
    final depts = _collegeSummary?.departmentSummaries ?? [];
    
    if (depts.isEmpty) {
      return const Center(child: Text('No department data available.'));
    }

    return Column(
      children: depts.map((dept) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.subtle,
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    dept.deptCode,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDeptMiniStat('Students', '${dept.studentCount}'),
                        _buildDeptMiniStat('Attendance', '${dept.avgAttendance}%'),
                        _buildDeptMiniStat('At-Risk', '${dept.atRiskCount}', isWarning: dept.atRiskCount > 5),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: dept.avgAttendance / 100,
                        backgroundColor: AppColors.surface,
                        color: _getAttendanceColor(dept.avgAttendance),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeptMiniStat(String label, String value, {bool isWarning = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isWarning ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getAttendanceColor(double attendance) {
    if (attendance >= 90) return AppColors.success;
    if (attendance >= 75) return AppColors.primary;
    return AppColors.error;
  }
}
