import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';

class ProjectRoadmapScreen extends StatefulWidget {
  final Map<String, dynamic> batch;

  const ProjectRoadmapScreen({super.key, required this.batch});

  @override
  State<ProjectRoadmapScreen> createState() => _ProjectRoadmapScreenState();
}

class _ProjectRoadmapScreenState extends State<ProjectRoadmapScreen> {
  late Map<String, dynamic> _batch;

  @override
  void initState() {
    super.initState();
    _batch = widget.batch;
  }

  Future<void> _refreshData() async {
    try {
      final updatedBatch = await ApiService().getMyProjectBatch();
      if (updatedBatch != null) {
        setState(() {
          _batch = updatedBatch;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing data: $e')),
      );
    }
  }

  Future<void> _toggleTask(int taskId, int currentStatus) async {
    try {
      final newStatus = currentStatus == 1 ? 0 : 1;
      await ApiService().updateProjectTask(taskId, newStatus);
      await _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _batch['tasks'] as List<dynamic>? ?? [];
    final reviews = _batch['reviews'] as List<dynamic>? ?? [];
    
    // Group tasks by phase
    final phases = <String, List<dynamic>>{};
    for (var task in tasks) {
      final phase = task['phase'] as String;
      phases.putIfAbsent(phase, () => []).add(task);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(
            'Project Roadmap',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Roadmap'),
              Tab(text: 'Assessments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRoadmapTab(phases),
            _buildAssessmentsTab(reviews),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapTab(Map<String, List<dynamic>> phases) {
    if (phases.isEmpty) {
      return const Center(child: Text('No tasks found.'));
    }

    final sortedPhases = phases.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedPhases.length,
        itemBuilder: (context, index) {
          final phaseName = sortedPhases[index];
          final phaseTasks = phases[phaseName]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  phaseName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              ...phaseTasks.map((task) => _buildTaskItem(task)),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(dynamic task) {
    final bool isDone = task['is_completed'] == 1;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.subtle,
      ),
      child: CheckboxListTile(
        title: Text(
          task['task_name'],
          style: GoogleFonts.inter(
            fontSize: 14,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : AppColors.textPrimary,
          ),
        ),
        value: isDone,
        activeColor: AppColors.primary,
        onChanged: (val) => _toggleTask(task['id'], task['is_completed']),
      ),
    );
  }

  Widget _buildAssessmentsTab(List<dynamic> reviews) {
    // We expect 3 reviews
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReviewCard(1, reviews.firstWhere((r) => r['review_number'] == 1, orElse: () => null)),
        _buildReviewCard(2, reviews.firstWhere((r) => r['review_number'] == 2, orElse: () => null)),
        _buildReviewCard(3, reviews.firstWhere((r) => r['review_number'] == 3, orElse: () => null)),
      ],
    );
  }

  Widget _buildReviewCard(int number, dynamic review) {
    final bool isCompleted = review != null;
    final String title = number == 3 ? 'Review 3 (Model Exam)' : 'Review $number';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.subtle,
        border: isCompleted ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? AppColors.primary : Colors.grey,
              ),
            ),
            title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            subtitle: Text(isCompleted ? 'Assessment Completed' : 'Pending Evaluation'),
            trailing: isCompleted 
              ? Text(
                  '${review['marks']} Marks',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                )
              : null,
          ),
          if (isCompleted && review['feedback'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 4),
                  Text(
                    'FACULTY FEEDBACK:',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review['feedback'],
                    style: GoogleFonts.inter(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
