import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_scaffold.dart';
import 'student_attendance_screen.dart';
import 'student_activity_screen.dart';
import 'student_marks_screen.dart';
import 'student_profile_screen.dart';
import 'student_risk_screen.dart';
import 'subject_listing_screen.dart';
import 'cgpa_screen.dart';
import 'learning_hub_screen.dart';
import 'quiz_screen.dart';
// import 'overall_learning_screen.dart';



void _handleLogout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/role-selection', (route) => false);
  }
}

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: ApiService().getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        final isWideScreen = MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;
        
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      _handleLogout(context);
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          },
          child: isWideScreen ? _buildWebLayout(user) : _buildMobileLayout(user),
        );
      },
    );
  }

  Widget _buildWebLayout(User? user) {
    return WebScaffold(
      title: 'Student Dashboard',
      subtitle: user?.name ?? 'Welcome',
      selectedIndex: _selectedIndex,
      actions: [
        if (user?.role == 'student' && user?.regNo != null)
          FutureBuilder<RiskPrediction>(
            future: ApiService().predictRisk(user!.regNo!),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.riskLevel == 'Low') {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                    ),
                    icon: const Icon(Icons.school, color: Colors.white),
                    label: const Text('Learning Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
      navigationItems: [
        NavigationItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          onTap: () => setState(() => _selectedIndex = 0),
        ),
        NavigationItem(
          icon: Icons.person_outline,
          label: 'Profile',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProfileScreen())),
        ),
        NavigationItem(
          icon: Icons.assignment_outlined,
          label: 'View Marks',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentMarksScreen())),
        ),
        NavigationItem(
          icon: Icons.calendar_today_outlined,
          label: 'Attendance',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAttendanceScreen())),
        ),
      ],
      userHeader: _buildUserHeader(user),
      onLogout: () => _handleLogout(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ContentConstraints(
          maxWidth: 1400,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 32),
              _buildPendingQuizzes(),
              const SizedBox(height: 32),
              _buildSummaryCards(),
              const SizedBox(height: 32),
              _buildAcademicAlerts(),
              const SizedBox(height: 32),
              _buildPersonalizedLearning(),
              const SizedBox(height: 32),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(context, user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(User? user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (user?.role == 'student' && user?.regNo != null)
            FutureBuilder<RiskPrediction>(
              future: ApiService().predictRisk(user!.regNo!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.riskLevel == 'Low') {
                  return IconButton(
                    icon: const Icon(Icons.school, color: Colors.greenAccent),
                    tooltip: 'Learning Plan',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          FutureBuilder<User>(
            future: ApiService().getCurrentUser(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final user = snapshot.data!;
              return PopupMenuButton<String>(
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
                  if (value == 'logout') _handleLogout(context);
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    child: Row(children: [Icon(Icons.logout, size: 20), SizedBox(width: 12), Text('Logout')]),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildPendingQuizzes(),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildAcademicAlerts(),
            const SizedBox(height: 24),
            _buildPersonalizedLearning(),
            const SizedBox(height: 24),
            _buildActionButtons(context, user),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicAlerts() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService().getStudentAlerts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide if no alerts
        }
        
        // Filter out read alerts
        final activeAlerts = snapshot.data!.where((a) => a['is_read'] == 0).toList();
        if (activeAlerts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Important Academic Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 12),
            ...activeAlerts.map((alert) {
              return Card(
                color: Colors.red.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200, width: 1),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert['subject'] ?? 'Academic Alert',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert['message'] ?? 'High risk detected. Please review your learning plan.',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () async {
                                  try {
                                    await ApiService().markAlertRead(alert['id']);
                                    setState(() {}); // Refresh to hide the alert
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Acknowledge'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildUserHeader(User? user) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            user?.name[0].toUpperCase() ?? 'S',
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
                user?.name ?? 'Student',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService().getStudentDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        
        final stats = snapshot.data;
        final studentInfo = stats?['student_info'];
        
        return Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                studentInfo?['name']?[0]?.toUpperCase() ?? 'S',
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
                    studentInfo?['name'] ?? 'Student',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    studentInfo?['reg_no'] ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${studentInfo?['dept'] ?? ''} - Year ${studentInfo?['year'] ?? ''} ${studentInfo?['section'] != null ? "Sec ${studentInfo!['section']}" : ""}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }



  Widget _buildSummaryCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService().getStudentDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final stats = snapshot.data;
        
        final List<Map<String, dynamic>> summaryData = [
          {
            'title': 'Attendance',
            'value': '${stats?['attendance_percentage']?.toStringAsFixed(1) ?? '0'}%',
            'icon': Icons.calendar_today,
            'color': Colors.blue,
          },
          {
            'title': 'GPA',
            'value': '${stats?['gpa']?.toStringAsFixed(1) ?? '0.0'}',
            'icon': Icons.school,
            'color': Colors.green,
          },
          {
            'title': 'Activities',
            'value': '${stats?['activities_count'] ?? '0'}',
            'icon': Icons.local_activity,
            'color': Colors.orange,
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
            childAspectRatio: crossAxisCount >= 4 ? 1.8 : 1.9, 
          ),
          itemCount: summaryData.length,
          itemBuilder: (context, index) {
            final data = summaryData[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (data['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(data['icon'], color: data['color'], size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              data['value'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              data['title'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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

  Widget _buildActionButtons(BuildContext context, User? user) {
    final List<Map<String, dynamic>> actions = [
      {
        'label': 'Risk Checker',
        'icon': Icons.health_and_safety_outlined,
        'color': Colors.redAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentRiskScreen(),
            ),
          );
        },
      },
      {
        'label': 'View Profile',
        'icon': Icons.person_outline,
        'color': Colors.blue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentProfileScreen(),
            ),
          );
        },
      },
      {
        'label': 'View Marks',
        'icon': Icons.assignment_outlined,
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentMarksScreen(),
            ),
          );
        },
      },
      {
        'label': 'Attendance',
        'icon': Icons.calendar_today_outlined,
        'color': Colors.orange,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentAttendanceScreen(),
            ),
          );
        },
      },
      {
        'label': 'Activities',
        'icon': Icons.local_activity_outlined,
        'color': Colors.purple,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentActivityScreen(),
            ),
          );
        },
      },
      {
        'label': 'Subjects',
        'icon': Icons.menu_book_outlined,
        'color': Colors.teal,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubjectListingScreen(),
            ),
          );
        },
      },
      {
        'label': 'CGPA',
        'icon': Icons.calculate_outlined,
        'color': Colors.deepPurple,
        'onTap': () {
          // reg_no is available from the student profile loaded in dashboard
          final regNo = user?.regNo ?? '';
          if (regNo.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CgpaScreen(regNo: regNo),
            ),
          );
        },
      },
    ];

    final crossAxisCount = ResponsiveBreakpoints.getCrossAxisCount(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 5,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action['icon'],
                      color: action['color'],
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    action['label'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildPersonalizedLearning() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personalized Learning',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: ApiService().getLearningRecommendations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('Error loading resources: ${snapshot.error}');
            }
            
            final data = snapshot.data ?? {};
            final resourcesList = data['resources'] is List ? data['resources'] as List<dynamic> : [];
            final resources = resourcesList.map((json) => LearningResource.fromJson(json)).toList();
            final progress = data['progress'] is Map<String, dynamic> ? data['progress'] : {};
            final progressPercentage = (progress['percentage'] as num?)?.toDouble() ?? 0.0;
            
            if (resources.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recommended resources found at this time.'),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            '${progressPercentage.toInt()}% Completed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressPercentage / 100,
                        backgroundColor: Colors.blue.shade100,
                        color: Colors.blue.shade700,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Resources List
                SizedBox(
                  height: 240, // Increased height to prevent overflow
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: resources.length,
                    itemBuilder: (context, index) {
                      final resource = resources[index];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getResourceColor(resource.type).withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(_getResourceIcon(resource.type), size: 16, color: _getResourceColor(resource.type)),
                                  const SizedBox(width: 8),
                                  Text(
                                    resource.type.toUpperCase(),
                                    style: TextStyle(
                                      color: _getResourceColor(resource.type),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (resource.dept != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        resource.dept!,
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resource.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resource.description ?? 'No description',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    if (resource.tags != null)
                                      Wrap(
                                        spacing: 4,
                                        children: resource.tags!.split(',').take(2).map((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tag.trim(),
                                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final uri = Uri.parse(resource.url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                  child: const Text('View'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
            
            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: resources.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final resource = resources[index];
                  return SizedBox(
                    width: 280,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () async {
                          final uri = Uri.parse(resource.url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getResourceColor(resource.type).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  resource.type.toUpperCase(),
                                  style: TextStyle(
                                    color: _getResourceColor(resource.type),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                resource.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  resource.description ?? '',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (resource.tags != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Wrap(
                                    spacing: 4,
                                    children: resource.tags!.split(',').take(2).map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tag.trim(),
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getResourceColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Colors.red;
      case 'article':
        return Colors.green;
      case 'course':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _getResourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_fill;
      case 'article':
        return Icons.article;
      case 'course':
        return Icons.school;
      default:
        return Icons.link;
    }
  }

  Widget _buildPendingQuizzes() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService().getPendingQuizzes(),
      builder: (context, snapshot) {
        final quizzes = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.quiz, color: Colors.purple.shade700, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Early Risk Quiz',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (quizzes.isEmpty)
              // Placeholder card when no quiz is scheduled
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade50, Colors.indigo.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade100, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.quiz_outlined, color: Colors.purple.shade400, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Quiz Scheduled Yet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.purple.shade800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your faculty will schedule a quiz before each assessment (Slip Test, CIA, Model Exam). Completing it helps predict and reduce your academic risk early.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_active_outlined, size: 13, color: Colors.purple.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Quiz available before every assessment',
                                  style: TextStyle(fontSize: 11, color: Colors.purple.shade700, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              // Active quiz cards
              ...quizzes.map((quiz) {
                final deadline = DateTime.parse(quiz['deadline']).toLocal();
                final isOverdue = DateTime.now().isAfter(deadline);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade700, Colors.purple.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              subjectCode: quiz['subject_code'],
                              subjectTitle: quiz['subject_title'],
                              unitNumber: quiz['unit_number'],
                              riskLevel: 'MEDIUM',
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.quiz, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Unit ${quiz['unit_number']} - ${quiz['assessment_type']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (isOverdue) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.shade400,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('OVERDUE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    quiz['subject_title'] ?? quiz['subject_code'],
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (quiz['start_time'] != null) ...[
                                        const Icon(Icons.play_circle_outline, color: Colors.white70, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Starts: ${DateTime.parse(quiz['start_time']).toLocal().day}/${DateTime.parse(quiz['start_time']).toLocal().month}/${DateTime.parse(quiz['start_time']).toLocal().year}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      const Icon(Icons.schedule, color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Due: ${deadline.day}/${deadline.month}/${deadline.year} ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

// test 
