import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_scaffold.dart';
import 'students_list_screen.dart';
import 'analytics_screen.dart';
import 'activity_management_screen.dart';
import 'activity_management_screen.dart';
import 'activity_approval_screen.dart';
import 'attendance_entry_screen.dart';
import 'faculty_allocation_screen.dart';
import 'subject_selection_screen.dart';
import 'project_batch_allocation_screen.dart';
import '../config/app_theme.dart';
import '../widgets/main_scaffold.dart';

void _handleLogout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/role-selection', (route) => false);
  }
}

class HODDashboardScreen extends StatefulWidget {
  const HODDashboardScreen({super.key});

  @override
  State<HODDashboardScreen> createState() => _HODDashboardScreenState();
}

class _HODDashboardScreenState extends State<HODDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: ApiService().getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error loading user data: ${snapshot.error}'),
            ),
          );
        }
        
        final user = snapshot.data;
        
        if (user == null || user.dept == null) {
          return _buildIncompleteAccountScreen();
        }
        
        return MainScaffold(
          title: 'HOD Dashboard',
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: [
            const NavDestination(icon: Icons.dashboard_rounded, label: 'Dashboard'),
            const NavDestination(icon: Icons.people_rounded, label: 'Students'),
            const NavDestination(icon: Icons.analytics_rounded, label: 'Analytics'),
            const NavDestination(icon: Icons.verified_user_rounded, label: 'Approvals'),
            const NavDestination(icon: Icons.school_rounded, label: 'Faculty'),
            const NavDestination(icon: Icons.library_books_rounded, label: 'Subjects'),
          ],
          onLogout: () => _handleLogout(context),
          body: _buildBody(user),
        );
      },
    );
  }

  Widget _buildBody(User user) {
    final dept = user.dept!;
    // Redirect if specific destination is selected (since this HOD dash uses separate screens for most items)
    if (_selectedIndex == 1) {
      Future.microtask(() => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentsListScreen(dept: dept, year: null, section: null))));
      _selectedIndex = 0;
    } else if (_selectedIndex == 2) {
      Future.microtask(() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())));
      _selectedIndex = 0;
    } else if (_selectedIndex == 3) {
      Future.microtask(() => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityApprovalScreen(dept: dept, year: 1, section: 'A'))));
      _selectedIndex = 0;
    } else if (_selectedIndex == 4) {
      Future.microtask(() => Navigator.push(context, MaterialPageRoute(builder: (_) => FacultyAllocationScreen(dept: dept))));
      _selectedIndex = 0;
    } else if (_selectedIndex == 5) {
      Future.microtask(() => Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectSelectionScreen(dept: dept))));
      _selectedIndex = 0;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(user),
          const SizedBox(height: 32),
          _buildSummaryCards(),
          const SizedBox(height: 32),
          SectionHeader(title: 'Department Actions', icon: Icons.grid_view_rounded, color: AppColors.primary),
          const SizedBox(height: 16),
          _buildQuickActions(context, user),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(User user) {
    final dept = user.dept!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HOD Dashboard'),
            Text(
              'Department: $dept',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            tooltip: 'Profile',
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text('Role: ${user.role}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [Icon(Icons.logout, size: 20), SizedBox(width: 12), Text('Logout')],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(user),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            const Text(
              'Department Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildQuickActions(context, user),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(User user) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            user.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                user.role,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(User? user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            user?.name[0].toUpperCase() ?? 'H',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user?.name ?? "HOD"}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Department: ${user?.dept ?? "Unknown"}',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<DashboardStats>(
      future: ApiService().getDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data;
        
        // HOD views Global (Department) stats
        final List<Map<String, dynamic>> summaryData = [
          {'title': 'Total Students', 'value': stats?.totalStudents.toString() ?? '0', 'icon': Icons.group, 'color': Colors.blue},
          {'title': 'Average Attendance', 'value': '${stats?.avgAttendance.toStringAsFixed(1) ?? '0'}%', 'icon': Icons.check_circle, 'color': Colors.green},
          {'title': 'At-Risk Students', 'value': stats?.atRiskCount.toString() ?? '0', 'icon': Icons.warning_amber, 'color': Colors.redAccent},
          {'title': 'Activities', 'value': stats?.totalActivities.toString() ?? '0', 'icon': Icons.emoji_events, 'color': Colors.orange},
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
            final data = summaryData[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: data['color'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(data['icon'], color: data['color'], size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['value'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            data['title'],
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, User? user) {
    final List<Map<String, dynamic>> actions = [
      {'label': 'All Students', 'icon': Icons.list_alt, 'color': Colors.blue, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentsListScreen(dept: user?.dept ?? '', year: null, section: null)))},
      {'label': 'Department Reports', 'icon': Icons.analytics, 'color': Colors.indigo, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))},
      {'label': 'Activity Approvals', 'icon': Icons.approval, 'color': Colors.deepOrange, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityApprovalScreen(dept: user!.dept!, year: 1, section: 'A')))},
      {'label': 'Faculty Allocation', 'icon': Icons.school, 'color': Colors.green, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => FacultyAllocationScreen(dept: user!.dept!)))},
      {'label': 'Subject Selection', 'icon': Icons.library_books, 'color': Colors.teal, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectSelectionScreen(dept: user!.dept!)))},
      {'label': 'Project Batches', 'icon': Icons.group_work, 'color': Colors.purple, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectBatchAllocationScreen(dept: user!.dept!)))},
    ];

    final crossAxisCount = ResponsiveBreakpoints.getCrossAxisCount(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 6,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: crossAxisCount >= 6 ? 0.95 : 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return HoverScaleEffect(
          onTap: action['onTap'],
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(action['icon'], color: action['color'], size: 28),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      action['label'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncompleteAccountScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Setup Required'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined, size: 80, color: AppColors.textSecondary),
              const SizedBox(height: 24),
              Text(
                'Department Not Assigned',
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your account has not been assigned to a department yet. Please contact the administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _handleLogout(context),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
