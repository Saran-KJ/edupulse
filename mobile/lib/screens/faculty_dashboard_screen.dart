import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';
import 'quiz_status_screen.dart';
import 'class_quiz_scores_screen.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/responsive_layout.dart';
import 'student_dashboard_screen.dart';
import 'attendance_entry_screen.dart';
import 'new_mark_entry_screen.dart';
import 'project_roadmap_screen.dart';
import 'project_batch_allocation_screen.dart';
import 'project_coordinator_management_screen.dart';
import '../widgets/project_dialogs.dart';

void _handleLogout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/role-selection', (route) => false);
  }
}

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
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
          return _buildErrorScreen('Error loading user data: ${snapshot.error}');
        }
        
        final user = snapshot.data;
        if (user == null) {
          return _buildErrorScreen('User data not found');
        }
        
        return MainScaffold(
          title: 'Faculty Dashboard',
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: [
            const NavDestination(icon: Icons.dashboard_rounded, label: 'Dashboard'),
            const NavDestination(icon: Icons.school_rounded, label: 'My Classes'),
          ],
          onLogout: () => _handleLogout(context),
          body: _buildBody(user),
        );
      },
    );
  }

  Widget _buildBody(User user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(user),
          const SizedBox(height: 32),
          _buildSummaryCards(),
          const SizedBox(height: 32),
          SectionHeader(title: 'My Classes', icon: Icons.class_rounded, color: AppColors.info),
          const SizedBox(height: 16),
          _buildClassesList(),
          const SizedBox(height: 32),
          SectionHeader(
            title: 'Scheduled Quizzes',
            icon: Icons.assignment_turned_in_rounded,
            color: Colors.purple.shade600,
          ),
          const SizedBox(height: 16),
          _buildScheduledQuizzesList(),
          const SizedBox(height: 32),
          const SectionHeader(title: 'Project Guidance', icon: Icons.group_work_rounded, color: AppColors.info),
          const SizedBox(height: 16),
          _buildProjectBattchesList(user),
          const SizedBox(height: 32),
          _buildCoordinatorSection(user),
          const SizedBox(height: 40),
        ],
      ),
    );
  }


  Widget _buildUserHeader(User user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          child: Text(
            user.name[0].toUpperCase(),
            style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
              Text(user.role, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(User user) {
    return GradientBanner(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome Back,', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(user.name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      user.dept != null ? '${user.dept} • Faculty' : 'Faculty Member',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService().getFacultyDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data ?? {};
        
        final List<Map<String, dynamic>> summaryData = [
          {'title': 'Total Classes', 'value': stats['total_classes']?.toString() ?? '0', 'icon': Icons.class_, 'color': Colors.blue},
          {'title': 'Total Students', 'value': stats['total_students']?.toString() ?? '0', 'icon': Icons.group, 'color': Colors.green},
          {'title': 'Subjects Taught', 'value': stats['subjects_taught']?.toString() ?? '0', 'icon': Icons.book, 'color': Colors.orange},
        ];

        final crossAxisCount = ResponsiveBreakpoints.getCrossAxisCount(
          context,
          mobile: 1,
          tablet: 3,
          desktop: 3,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount >= 3 ? 2.5 : 3.0,
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

  Widget _buildClassesList() {
    return FutureBuilder<List<FacultyAllocation>>(
      future: ApiService().getFacultyAllocations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading classes: ${snapshot.error}'),
            ),
          );
        }

        final classes = snapshot.data ?? [];
        
        if (classes.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.class_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No classes assigned yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please contact HOD to assign classes to you',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final crossAxisCount = ResponsiveBreakpoints.getCrossAxisCount(
          context,
          mobile: 1,
          tablet: 2,
          desktop: 3,
        );

        if (crossAxisCount == 1) {
          // Mobile: Use a vertical list to prevent horizontal/aspect-ratio overflows
          return Column(
            children: classes.map((cls) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SizedBox(
                height: 180, // Fixed height or flexible depending on design
                child: _buildClassCard(cls),
              ),
            )).toList(),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final cls = classes[index];
            return _buildClassCard(cls);
          },
        );
      },
    );
  }

  Widget _buildClassCard(FacultyAllocation cls) {
    return HoverScaleEffect(
      onTap: () => _showClassOptions(context, cls.dept, cls.year, cls.section, cls.subjectCode, cls.subjectTitle),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.info.withValues(alpha: 0.15), AppColors.info.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: AppColors.info, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${cls.dept} • Year ${cls.year} ${cls.section}', style: AppTextStyles.label.copyWith(fontSize: 12)),
                        Text(cls.subjectCode, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                cls.subjectTitle.toUpperCase(),
                style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Divider(color: Colors.grey.shade200),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _navigateToMarks(cls.dept, cls.year, cls.section, cls.subjectCode, cls.subjectTitle),
                      icon: Icon(Icons.grade_rounded, size: 16, color: AppColors.success),
                      label: Text('Marks', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.shade200),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendanceEntryScreen(
                            dept: cls.dept,
                            year: cls.year,
                            section: cls.section,
                            subjectCode: cls.subjectCode,
                            subjectTitle: cls.subjectTitle,
                          ),
                        ),
                      ),
                      icon: Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.info),
                      label: Text('Attendance', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.info)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClassOptions(BuildContext context, String dept, int year, String section, String subjectCode, String subjectTitle) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$dept - Year $year $section',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              subjectTitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.grade),
              title: const Text('Enter Marks'),
              onTap: () {
                Navigator.pop(context);
                _navigateToMarks(dept, year, section, subjectCode, subjectTitle);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Enter Attendance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceEntryScreen(
                      dept: dept,
                      year: year,
                      section: section,
                      subjectCode: subjectCode,
                      subjectTitle: subjectTitle,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Schedule AI Quiz'),
              subtitle: const Text('For Early Risk Prediction'),
              onTap: () {
                Navigator.pop(context);
                _showScheduleQuizDialog(context, dept, year, section, subjectCode, subjectTitle);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditQuizDialog(BuildContext context, ScheduledQuiz quiz) {
    int selectedUnit = quiz.unitNumber;
    String selectedAssessment = quiz.assessmentType;
    DateTime selectedDate = quiz.deadline != null ? DateTime.parse(quiz.deadline!) : DateTime.now().add(const Duration(days: 7));
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Scheduled Quiz'),
              content: isLoading 
                ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${quiz.subjectTitle}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${quiz.dept} - Year ${quiz.year} ${quiz.section}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: 20),
                        
                        const Text('Target Assessment:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedAssessment,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          items: ['Slip Test', 'CIA', 'Model Exam'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) => setState(() => selectedAssessment = newValue!),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text('Syllabus Unit:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: selectedUnit,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          items: [1, 2, 3, 4, 5].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('Unit $value'),
                            );
                          }).toList(),
                          onChanged: (newValue) => setState(() => selectedUnit = newValue!),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text('Deadline:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              if (!context.mounted) return;
                              final TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedDate),
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  selectedDate = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                                const SizedBox(width: 10),
                                Text(
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: () async {
                    setState(() => isLoading = true);
                    try {
                      await ApiService().updateScheduledQuiz(quiz.id, {
                        'unit_number': selectedUnit,
                        'assessment_type': selectedAssessment,
                        'deadline': selectedDate.toIso8601String(),
                      });
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quiz updated successfully')),
                        );
                        this.setState(() {}); // Trigger refresh
                      }
                    } catch (e) {
                      setState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update quiz: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int quizId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scheduled Quiz'),
        content: const Text('Are you sure you want to delete this scheduled quiz? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService().deleteScheduledQuiz(quizId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quiz deleted successfully')),
                  );
                  this.setState(() {}); // Trigger refresh
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete quiz: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showScheduleQuizDialog(BuildContext context, String dept, int year, String section, String subjectCode, String subjectTitle) {
    int selectedUnit = 1;
    String selectedAssessment = 'CIA';
    DateTime selectedStartDate = DateTime.now();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Schedule Early Risk Quiz'),
              content: isLoading 
                ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$subjectTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('$dept - Year $year $section', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: 20),
                        
                        const Text('Target Assessment:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedAssessment,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          items: ['Slip Test', 'CIA', 'Model Exam'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) => setState(() => selectedAssessment = newValue!),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text('Syllabus Unit:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: selectedUnit,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          items: [1, 2, 3, 4, 5].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('Unit $value'),
                            );
                          }).toList(),
                          onChanged: (newValue) => setState(() => selectedUnit = newValue!),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text('Start Time:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedStartDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (pickedDate != null) {
                              if (!context.mounted) return;
                              final TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedStartDate),
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  selectedStartDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  // Ensure deadline is after start date
                                  if (selectedDate.isBefore(selectedStartDate)) {
                                    selectedDate = selectedStartDate.add(const Duration(hours: 1));
                                  }
                                });
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${selectedStartDate.day}/${selectedStartDate.month}/${selectedStartDate.year} ${TimeOfDay.fromDateTime(selectedStartDate).format(context)}',
                                ),
                                const Icon(Icons.access_time, size: 18),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text('Deadline:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: selectedStartDate, // Deadline cannot be before start date
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (pickedDate != null) {
                              if (!context.mounted) return;
                              final TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedDate),
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  selectedDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${TimeOfDay.fromDateTime(selectedDate).format(context)}',
                                ),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setState(() => isLoading = true);
                    try {
                      await ApiService().scheduleQuiz({
                        'dept': dept,
                        'year': year,
                        'section': section,
                        'subject_code': subjectCode,
                        'subject_title': subjectTitle,
                        'unit_number': selectedUnit,
                        'assessment_type': selectedAssessment,
                        'start_time': selectedStartDate.toIso8601String(),
                        'deadline': selectedDate.toIso8601String(),
                      });
                      
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quiz scheduled successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      setState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToMarks(String dept, int year, String section, [String? subjectCode, String? subjectTitle]) async {
    // Calculate semester based on year (e.g., year 1 => semester 1, year 2 => semester 3)
    final int semester = (year * 2) - 1;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final students = await ApiService().getStudents(
        dept: dept,
        year: year,
        section: section,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No students found in this class'), backgroundColor: Colors.orange),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewMarkEntryScreen(
            students: students,
            dept: dept,
            year: year,
            section: section,
            semester: semester,
            subjectCode: subjectCode,
            subjectTitle: subjectTitle,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openAddReviewDialog(Map<String, dynamic> batch) {
    showDialog(
      context: context,
      builder: (ctx) => AddReviewDialog(
        batch: batch,
        onReviewAdded: () => setState(() {}),
      ),
    );
  }

  Widget _buildProjectBattchesList(User user) {

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService().getGuideBatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final batches = snapshot.data ?? [];
        if (batches.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No project batches assigned for guidance.')),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final batch = batches[index];
            final students = batch['students'] as List<dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProjectRoadmapScreen(batch: batch)),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Batch #${batch['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: ApiService().getProjectCoordinators(batch['dept'] ?? ''),
                            builder: (context, coordSnapshot) {
                              final isReviewer = batch['reviewer_id'] == user.userId;
                              final isCoord = coordSnapshot.data?.any((c) => c['faculty_id'] == user.userId && c['year'] == batch['year']) ?? false;
                              
                              if (isReviewer || isCoord) {
                                return IconButton(
                                  icon: const Icon(Icons.rate_review_outlined, color: AppColors.primary),
                                  onPressed: () => _openAddReviewDialog(batch),
                                  tooltip: 'Add Review',
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        'Class: Year ${batch['year']} - ${batch['section']} (${batch['dept']})',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: students.map((s) => Chip(
                          label: Text(s['name'] ?? '', style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppColors.surface,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoordinatorSection(User user) {
    if (user.dept == null) return const SizedBox.shrink();
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService().getProjectCoordinators(user.dept!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Coord Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 10)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final isCoordinator = snapshot.data!.any((c) => 
          c['faculty_id'].toString() == user.userId.toString()
        );
        
        debugPrint('User ${user.userId} isCoordinator: $isCoordinator');
        
        if (!isCoordinator) {
          // Temporarily show why not coordinator for debugging
          // return Center(child: Text('Not a coord for ${user.dept}', style: TextStyle(fontSize: 10)));
          return const SizedBox.shrink();
        }

        final coordinatorData = snapshot.data!.firstWhere((c) => 
          c['faculty_id'].toString() == user.userId.toString()
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Project Coordination - Year ${coordinatorData['year']}', icon: Icons.admin_panel_settings, color: AppColors.primary),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.assignment_ind, color: AppColors.primary),
                ),
                title: const Text('Manage Department Project Batches', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Assign reviewers and track progress for Year ${coordinatorData['year']} students.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectCoordinatorManagementScreen(
                        dept: user.dept!,
                        assignedYear: coordinatorData['year'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduledQuizzesList() {
    return FutureBuilder<List<ScheduledQuiz>>(
      future: ApiService().getScheduledQuizzes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoQuizzesState();
        }

        final quizzes = snapshot.data!;
        return SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return _buildQuizCard(quiz);
            },
          ),
        );
      },
    );
  }

  Widget _buildQuizCard(ScheduledQuiz quiz) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizStatusScreen(
              quizId: quiz.id,
              subjectTitle: quiz.subjectTitle,
            ),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
          border: Border.all(color: Colors.purple.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.quiz_rounded, color: Colors.purple, size: 18),
                const Spacer(),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditQuizDialog(context, quiz);
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(context, quiz.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (quiz.isActive == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Closed', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              quiz.subjectTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
            ),
            const Spacer(),
            Text(
              '${quiz.dept} - ${quiz.year}${quiz.section}',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              'Unit ${quiz.unitNumber}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoQuizzesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.subtle,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, color: Colors.grey.shade300, size: 32),
          const SizedBox(height: 8),
          Text(
            'No active quizzes scheduled',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error Loading Data', style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


