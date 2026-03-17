import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_scaffold.dart';
import 'attendance_entry_screen.dart';
import 'new_mark_entry_screen.dart';

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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error loading user data: ${snapshot.error}'),
            ),
          );
        }
        
        final user = snapshot.data;
        if (user == null) {
          return _buildErrorScreen('User data not found');
        }
        
        final isWideScreen = MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;

        if (isWideScreen) {
          return _buildWebLayout(user);
        }
        return _buildMobileLayout(user);
      },
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Faculty Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.warning),
              const SizedBox(height: 16),
              Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(User user) {
    return WebScaffold(
      title: 'Faculty Dashboard',
      subtitle: user.dept != null ? '${user.dept} Department' : 'Faculty Member',
      selectedIndex: _selectedIndex,
      navigationItems: [
        NavigationItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          onTap: () => setState(() => _selectedIndex = 0),
        ),
        NavigationItem(
          icon: Icons.class_,
          label: 'My Classes',
          onTap: () => setState(() => _selectedIndex = 0),
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
              _buildWelcomeHeader(user),
              const SizedBox(height: 32),
              _buildSummaryCards(),
              const SizedBox(height: 32),
              const Text(
                'My Classes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildClassesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(User user) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Faculty Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                user.name[0].toUpperCase(),
                style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            tooltip: 'Profile',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'logout') _handleLogout(context);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(user.email, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Text('Role: ${user.role}', style: AppTextStyles.bodySmall),
                    const Divider(),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(children: [const Icon(Icons.logout_rounded, size: 18), const SizedBox(width: 12), Text('Logout', style: AppTextStyles.body)]),
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
            SectionHeader(title: 'My Classes', icon: Icons.class_rounded, color: AppColors.info),
            const SizedBox(height: 16),
            _buildClassesList(),
          ],
        ),
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

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.3,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showClassOptions(context, cls.dept, cls.year, cls.section, cls.subjectCode, cls.subjectTitle),
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
}

