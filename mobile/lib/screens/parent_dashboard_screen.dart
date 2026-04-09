import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import 'student_attendance_screen.dart';
import 'student_marks_screen.dart';
import 'student_activity_screen.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/main_scaffold.dart';

void _handleLogout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/role-selection', (route) => false);
  }
}

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = ApiService().getParentDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: ApiService().getCurrentUser(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        return MainScaffold(
          title: 'Parent Dashboard',
          selectedIndex: 0,
          onDestinationSelected: (index) {},
          destinations: const [
            NavDestination(icon: Icons.dashboard_rounded, label: 'Dashboard'),
          ],
          onLogout: () => _handleLogout(context),
          userName: user?.name,
          userRole: user?.role,
          actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => setState(() { _dashboardFuture = ApiService().getParentDashboardStats(); }),
        ),
      ],
          body: FutureBuilder<Map<String, dynamic>>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (snapshot.hasError) {
                return _buildErrorView(snapshot.error.toString());
              }

              final data = snapshot.data!;
              
              if (data.containsKey('error')) {
                return _buildChildNotFoundMessage(data);
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(data),
                    const SizedBox(height: 32),
                    _buildChildInfoCard(data),
                    const SizedBox(height: 32),
                    const SectionHeader(title: 'Academic Summary', icon: Icons.analytics_rounded, color: AppColors.primary),
                    const SizedBox(height: 16),
                    _buildSummaryCards(data),
                    const SizedBox(height: 32),
                    const SectionHeader(title: 'Quick Actions', icon: Icons.bolt_rounded, color: AppColors.accent),
                    const SizedBox(height: 16),
                    _buildQuickActions(context, data),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildNotFoundMessage(Map<String, dynamic> data) {
    final parentInfo = data['parent_info'] ?? {};
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${parentInfo['name'] ?? 'Parent'}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Child Not Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['message'] ?? 'Unable to find your child\'s record.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Looking for: ${parentInfo['child_name'] ?? 'N/A'}\nPhone: ${parentInfo['child_phone'] ?? 'N/A'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Please ensure your child\'s phone number matches their student record.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(Map<String, dynamic> data) {
    final parentInfo = data['parent_info'] ?? {};
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.colored(const Color(0xFF00897B)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.family_restroom,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.teal.shade50,
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        parentInfo['name'] ?? 'Parent',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (parentInfo['occupation'] != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            parentInfo['occupation'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildInfoCard(Map<String, dynamic> data) {
    final childInfo = data['child_info'] ?? {};
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.badge, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Student Profile',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    childInfo['reg_no'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade100,
                    child: Text(
                      (childInfo['name'] ?? 'S')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childInfo['name'] ?? 'Student',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(Icons.domain, childInfo['dept'] ?? '-'),
                          _buildInfoChip(Icons.calendar_today, 'Yr ${childInfo['year'] ?? '-'}'),
                          _buildInfoChip(Icons.class_, 'Sec ${childInfo['section'] ?? '-'}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> data) {
    // ... keep data prep ...
    final summaryData = [
      {
        'title': 'CGPA',
        'value': '${data['gpa']?.toStringAsFixed(2) ?? '0.00'}',
        'icon': Icons.grade,
        'color': Colors.green,
      },
      {
        'title': 'Attendance',
        'value': '${data['attendance_percentage']?.toStringAsFixed(1) ?? '0'}%',
        'icon': Icons.calendar_month,
        'color': Colors.blue,
      },
      {
        'title': 'Co/Extra-curricular',
        'value': '${data['activities_count'] ?? 0}',
        'icon': Icons.emoji_events,
        'color': Colors.orange,
      },
      {
        'title': 'Risk Status',
        'value': data['risk_level'] ?? 'LOW',
        'subValue': '${data['risk_score']?.toStringAsFixed(0) ?? '0'}%',
        'icon': Icons.insights,
        'color': _getRiskColor(data['risk_level']),
      },
    ];

    final crossAxisCount = ResponsiveBreakpoints.getCrossAxisCount(
      context,
      mobile: 2,
      tablet: 4,
      desktop: 4,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: crossAxisCount >= 4 ? 2.0 : 2.2,
      ),
      itemCount: summaryData.length,
      itemBuilder: (context, index) {
        final item = summaryData[index];
        final color = item['color'] as Color;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.card,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
          ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item['value'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item['subValue'] != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (item['color'] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['subValue'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        );
      },
    );
  }

  Color _getRiskColor(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
      default:
        return Colors.green;
    }
  }

  Widget _buildQuickActions(BuildContext context, Map<String, dynamic> data) {
    final childInfo = data['child_info'];
    final regNo = childInfo['reg_no'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Views',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Attendance',
                Icons.calendar_month_outlined,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentAttendanceScreen(regNo: regNo),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Marks',
                Icons.analytics_outlined,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentMarksScreen(regNo: regNo),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Co/Extra-curricular',
                Icons.emoji_events_outlined,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentActivityScreen(regNo: regNo),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
