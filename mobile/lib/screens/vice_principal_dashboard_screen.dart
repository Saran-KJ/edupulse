import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/responsive_layout.dart';
import '../config/app_theme.dart';
import '../widgets/main_scaffold.dart';
import 'role_selection_screen.dart';

class VicePrincipalDashboardScreen extends StatefulWidget {
  const VicePrincipalDashboardScreen({super.key});

  @override
  State<VicePrincipalDashboardScreen> createState() => _VicePrincipalDashboardScreenState();
}

class _VicePrincipalDashboardScreenState extends State<VicePrincipalDashboardScreen> {
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
      title: 'Vice Principal Dashboard',
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavDestination(icon: Icons.analytics_rounded, label: 'Overview'),
        NavDestination(icon: Icons.domain_rounded, label: 'Departments'),
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
        return _buildDepartmentBody();
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
              title: 'Academic Performance Sync',
              icon: Icons.sync_rounded,
              color: AppColors.info,
            ),
            const SizedBox(height: 16),
            _buildInstitutionalStats(),
            const SizedBox(height: 32),
            const SectionHeader(
              title: 'Departmental Breakdown',
              icon: Icons.bar_chart_rounded,
              color: AppColors.success,
            ),
            const SizedBox(height: 16),
            _buildDepartmentMatrix(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEPARTMENTAL OVERSIGHT',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.info,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Operational Metrics',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildDetailedDeptList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedDeptList() {
    final depts = _collegeSummary?.departmentSummaries ?? [];
    return Column(
      children: depts.map((dept) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.subtle,
            border: Border.all(color: AppColors.info.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        dept.deptCode,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Department of ${dept.deptCode}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${dept.studentCount} Students Enrolled',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(dept.avgAttendance),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricItem('Attendance', '${dept.avgAttendance}%', Icons.event_available_rounded, AppColors.success),
                  _buildMetricItem('At-Risk Students', '${dept.atRiskCount}', Icons.warning_amber_rounded, AppColors.error),
                  _buildMetricItem('High Performers', '${dept.highPerformerCount}', Icons.auto_awesome_rounded, AppColors.accentWarm),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatusChip(double attendance) {
    bool isHealthy = attendance >= 80;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isHealthy ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isHealthy ? 'Healthy' : 'Attention Reqd',
        style: TextStyle(
          color: isHealthy ? AppColors.success : AppColors.error,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLeadershipHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF34495E), Color(0xFF2C3E50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.3),
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
                child: const Icon(Icons.speed_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OPERATIONAL OVERSIGHT',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.lightBlueAccent.shade100,
                      letterSpacing: 2.5,
                    ),
                  ),
                  Text(
                    'Welcome, Vice Principal',
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
              _buildQuickMetric('TOTAL ENROLLED', '${_collegeSummary?.totalStudents ?? 0}'),
              const SizedBox(width: 24),
              _buildQuickMetric('ACTIVE DEPTS', '${_collegeSummary?.departmentSummaries.length ?? 0}'),
              const SizedBox(width: 24),
              _buildQuickMetric('HEALTH INDEX', '${_collegeSummary?.avgCollegeAttendance ?? 0}%'),
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
        'title': 'Average Attendance',
        'value': '${_collegeSummary?.avgCollegeAttendance ?? 0}%',
        'icon': Icons.calendar_month_rounded,
        'color': AppColors.info,
      },
      {
        'title': 'High Risk Count',
        'value': '${_collegeSummary?.totalAtRisk ?? 0}',
        'subtitle': 'Immediate Action',
        'icon': Icons.priority_high_rounded,
        'color': AppColors.error,
      },
      {
        'title': 'Mastery Elite',
        'value': '${_collegeSummary?.totalHighPerformers ?? 0}',
        'subtitle': 'Top Performers',
        'icon': Icons.auto_awesome_rounded,
        'color': AppColors.accentWarm,
      },
      {
        'title': 'Activity Pulse',
        'value': '${_collegeSummary?.totalActivities ?? 0}',
        'subtitle': 'Participation',
        'icon': Icons.interests_rounded,
        'color': AppColors.primary,
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
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    dept.deptCode,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: AppColors.info,
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
                        _buildDeptMiniStat('High Performers', '${dept.highPerformerCount}'),
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

  Widget _buildDeptMiniStat(String label, String value) {
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
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getAttendanceColor(double attendance) {
    if (attendance >= 90) return AppColors.success;
    if (attendance >= 75) return AppColors.info;
    return AppColors.error;
  }
}
