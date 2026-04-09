import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'project_hub_screen.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../config/app_theme.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/main_scaffold.dart';
import 'student_attendance_screen.dart';
import 'student_activity_screen.dart';
import 'student_marks_screen.dart';
import 'student_profile_screen.dart';
import 'student_risk_screen.dart';
import 'subject_listing_screen.dart';
import 'cgpa_screen.dart';
import 'quiz_screen.dart';
import 'learning_hub_screen.dart';



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
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = ApiService().getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final user = snapshot.data;
        
        String title = 'Student Dashboard';
        if (_selectedIndex == 1) title = 'My Profile';
        if (_selectedIndex == 2) title = 'My Marks';
        if (_selectedIndex == 3) title = 'My Attendance';

        return MainScaffold(
          title: title,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: const [
            NavDestination(icon: Icons.dashboard_rounded, label: 'Dashboard'),
            NavDestination(icon: Icons.person_outline_rounded, label: 'Profile'),
            NavDestination(icon: Icons.assignment_outlined, label: 'View Marks'),
            NavDestination(icon: Icons.calendar_today_outlined, label: 'Attendance'),
          ],
          onLogout: () => _handleLogout(context),
          userName: user?.name,
          userRole: user?.role,
          onProfileTap: () => setState(() => _selectedIndex = 1),
          body: _buildSelectedBody(user),
        );
      },
    );
  }

  Widget _buildSelectedBody(User? user) {
    switch (_selectedIndex) {
      case 0:
        return _buildBody(user);
      case 1:
        return const StudentProfileScreen(hideScaffold: true);
      case 2:
        return const StudentMarksScreen(hideScaffold: true);
      case 3:
        return const StudentAttendanceScreen(hideScaffold: true);
      default:
        return _buildBody(user);
    }
  }

  Widget _buildBody(User? user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildProjectBatch(),
          const SizedBox(height: 28),
          _buildPendingQuizzes(),
          const SizedBox(height: 28),
          _buildSummaryCards(),
          const SizedBox(height: 28),
          _buildAcademicAlerts(),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Quick Actions',
            icon: Icons.bolt_rounded,
            color: AppColors.accentWarm,
          ),
          const SizedBox(height: 16),
          _buildActionButtons(context, user),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAcademicAlerts() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService().getStudentAlerts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final activeAlerts = snapshot.data!.where((a) => a['is_read'] == 0).toList();
        if (activeAlerts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Academic Alerts',
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            ...activeAlerts.map((alert) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
                  boxShadow: AppShadows.subtle,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['subject'] ?? 'Academic Alert',
                            style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert['message'] ?? 'High risk detected. Please review your learning plan.',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                try {
                                  await ApiService().markAlertRead(alert['id']);
                                  setState(() {});
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                              label: Text('Acknowledge', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
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
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: AppTextStyles.body));
        }

        final stats = snapshot.data;

        final List<Map<String, dynamic>> summaryData = [
          {
            'title': 'Attendance',
            'value': '${stats?['attendance_percentage']?.toStringAsFixed(1) ?? '0'}%',
            'icon': Icons.calendar_month_rounded,
            'color': AppColors.info,
          },
          {
            'title': 'GPA',
            'value': '${stats?['gpa']?.toStringAsFixed(1) ?? '0.0'}',
            'icon': Icons.school_rounded,
            'color': AppColors.success,
          },
          {
            'title': 'Co/Extra-curricular',
            'value': '${stats?['activities_count'] ?? '0'}',
            'icon': Icons.emoji_events_rounded,
            'color': AppColors.accentWarm,
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
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: crossAxisCount >= 4 ? 2.0 : 2.0,
          ),
          itemCount: summaryData.length,
          itemBuilder: (context, index) {
            final data = summaryData[index];
            return StatCard(
              title: data['title'],
              value: data['value'],
              icon: data['icon'],
              color: data['color'],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, User? user) {
    final List<Map<String, dynamic>> actions = [
      {
        'label': 'Academic Status',
        'icon': Icons.shield_rounded,
        'color': AppColors.error,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRiskScreen())),
      },
      {
        'label': 'View Profile',
        'icon': Icons.person_rounded,
        'color': AppColors.info,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProfileScreen())),
      },
      {
        'label': 'View Marks',
        'icon': Icons.assignment_rounded,
        'color': AppColors.success,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentMarksScreen())),
      },
      {
        'label': 'Attendance',
        'icon': Icons.calendar_month_rounded,
        'color': AppColors.accentWarm,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAttendanceScreen())),
      },
      {
        'label': 'Co/Extra-curricular',
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFFAB47BC),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentActivityScreen())),
      },
      {
        'label': 'Subjects',
        'icon': Icons.menu_book_rounded,
        'color': AppColors.accent,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubjectListingScreen())),
      },
      {
        'label': 'CGPA',
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFF5C6BC0),
        'onTap': () {
          final regNo = user?.regNo ?? '';
          if (regNo.isEmpty) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => CgpaScreen(regNo: regNo)));
        },
      },
      {
        'label': 'Skill Hub',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF6200EE),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningHubScreen())),
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
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: crossAxisCount <= 2 ? 1.1 : 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return HoverScaleEffect(
          onTap: action['onTap'],
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.card,
              border: Border.all(color: (action['color'] as Color).withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (action['color'] as Color).withValues(alpha: 0.15),
                        (action['color'] as Color).withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action['icon'],
                    color: action['color'],
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  action['label'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
            const SectionHeader(
              title: 'Early Risk Quiz',
              icon: Icons.quiz_rounded,
              color: Color(0xFF7B2FF7),
            ),
            const SizedBox(height: 12),

            if (isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (quizzes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppShadows.subtle,
                  border: Border.all(color: const Color(0xFF7B2FF7).withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF7B2FF7).withValues(alpha: 0.15), const Color(0xFF7B2FF7).withValues(alpha: 0.05)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.quiz_outlined, color: const Color(0xFF7B2FF7).withValues(alpha: 0.6), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Quiz Scheduled Yet',
                            style: AppTextStyles.headingSmall.copyWith(fontSize: 15, color: const Color(0xFF7B2FF7)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your faculty will schedule a quiz before each assessment. Completing it helps predict and reduce your academic risk early.',
                            style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B2FF7).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.notifications_active_outlined, size: 12, color: Color(0xFF7B2FF7)),
                                const SizedBox(width: 4),
                                Text(
                                  'Available before every assessment',
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF7B2FF7), fontWeight: FontWeight.w600),
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
              ...quizzes.map((quiz) {
                final deadline = DateTime.parse(quiz['deadline']).toLocal();
                final isOverdue = DateTime.now().isAfter(deadline);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF3F37C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppShadows.colored(const Color(0xFF7B2FF7)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              subjectCode: quiz['subject_code'],
                              subjectTitle: quiz['subject_title'],
                              unitNumber: quiz['unit_number'],
                              riskLevel: 'MEDIUM',
                              scheduledQuizId: quiz['id'],
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Unit ${quiz['unit_number']} • ${quiz['assessment_type']}',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (isOverdue) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text('OVERDUE', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    quiz['subject_title'] ?? quiz['subject_code'],
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (quiz['start_time'] != null) ...[
                                        const Icon(Icons.play_circle_outline_rounded, color: Colors.white60, size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Starts: ${DateTime.parse(quiz['start_time']).toLocal().day}/${DateTime.parse(quiz['start_time']).toLocal().month}/${DateTime.parse(quiz['start_time']).toLocal().year}',
                                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      const Icon(Icons.schedule_rounded, color: Colors.white60, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Due: ${deadline.day}/${deadline.month}/${deadline.year} ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.5), size: 14),
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

  Widget _buildProjectBatch() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiService().getMyProjectBatch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final batch = snapshot.data;
        if (batch == null) {
          return const SizedBox.shrink(); // Hide entirely if no batch assigned
        }

        final guideName = batch['guide_name'] ?? 'Unknown Guide';
        final students = batch['students'] as List<dynamic>? ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'My Project Batch',
              icon: Icons.group_work_rounded,
              color: AppColors.info,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectHubScreen(batch: batch),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.subtle,
                border: Border.all(color: AppColors.info.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: AppColors.info, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guided by',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              guideName,
                              style: AppTextStyles.headingSmall.copyWith(fontSize: 15, color: AppColors.info),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Text(
                    'Team Members:',
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: students.map((s) {
                      return Chip(
                        label: Text(
                          '${s['name']} ${s['reg_no'] != null ? '(${s['reg_no']})' : ''}',
                          style: AppTextStyles.bodySmall,
                        ),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: Colors.grey.shade300),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
      },
    );
  }
}
