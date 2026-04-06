import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class StudentActivityScreen extends StatefulWidget {
  final String? regNo;
  const StudentActivityScreen({super.key, this.regNo});

  @override
  State<StudentActivityScreen> createState() => _StudentActivityScreenState();
}

class _StudentActivityScreenState extends State<StudentActivityScreen> {
  List<StudentActivitySubmission> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      List<StudentActivitySubmission> submissions;
      if (widget.regNo != null) {
        submissions = await ApiService().getStudentActivities(widget.regNo!);
      } else {
        submissions = await ApiService().getMySubmissions();
      }
      setState(() {
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type) {
      case 'Sports':
        return Icons.sports;
      case 'Hackathon':
        return Icons.code;
      case 'Workshop':
        return Icons.build;
      case 'Symposium':
        return Icons.groups;
      case 'Seminar':
        return Icons.school;
      case 'Competition':
        return Icons.emoji_events;
      default:
        return Icons.local_activity;
    }
  }

  void _showAddActivityDialog() {
    final formKey = GlobalKey<FormState>();
    String activityName = '';
    String activityType = 'Sports';
    String level = 'College';
    DateTime activityDate = DateTime.now();
    String description = '';
    String role = 'Participant';
    String achievement = '';

    final activityTypes = ['Sports', 'Hackathon', 'Workshop', 'Symposium', 'Seminar', 'Competition', 'Other'];
    final levels = ['College', 'State', 'National', 'International'];
    final roles = ['Participant', 'Winner', 'Organizer', 'Volunteer', 'Speaker'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  const Text('Submit Co/Extra-curricular'),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Event/Activity Name *',
                            prefixIcon: const Icon(Icons.event),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          onSaved: (v) => activityName = v!,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: activityType,
                          decoration: InputDecoration(
                            labelText: 'Category *',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: activityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setDialogState(() => activityType = v!),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: level,
                          decoration: InputDecoration(
                            labelText: 'Level',
                            prefixIcon: const Icon(Icons.leaderboard),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                          onChanged: (v) => setDialogState(() => level = v!),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: activityDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => activityDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Event Date *',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(DateFormat('yyyy-MM-dd').format(activityDate)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Description',
                            prefixIcon: const Icon(Icons.description),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          maxLines: 3,
                          onSaved: (v) => description = v ?? '',
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: role,
                          decoration: InputDecoration(
                            labelText: 'Your Role',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (v) => setDialogState(() => role = v!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Achievement (if any)',
                            prefixIcon: const Icon(Icons.emoji_events),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            hintText: 'e.g. 1st Place, Best Paper',
                          ),
                          onSaved: (v) => achievement = v ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('Submit'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      try {
                        await ApiService().submitActivity({
                          'activity_name': activityName,
                          'activity_type': activityType,
                          'level': level,
                          'activity_date': DateFormat('yyyy-MM-dd').format(activityDate),
                          'description': description,
                          'role': role,
                          'achievement': achievement.isEmpty ? null : achievement,
                        });
                        if (mounted) Navigator.pop(context);
                        _loadSubmissions();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Activity submitted for approval!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.regNo != null ? 'Co-curricular & Extra-curricular' : 'My Co/Extra-curricular'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: widget.regNo == null
          ? FloatingActionButton.extended(
              onPressed: _showAddActivityDialog,
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Submit Co/Extra-curricular'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_activity_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No co/extra-curricular records found',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below to submit your first record',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubmissions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _submissions.length,
                    itemBuilder: (context, index) {
                      final sub = _submissions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getActivityTypeIcon(sub.activityType),
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub.activityName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${sub.activityType} • ${sub.level ?? ""}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(sub.status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_getStatusIcon(sub.status), size: 16, color: _getStatusColor(sub.status)),
                                        const SizedBox(width: 4),
                                        Text(
                                          sub.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(sub.status),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(sub.activityDate, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                  const SizedBox(width: 16),
                                  if (sub.role != null) ...[
                                    Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(sub.role!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                  ],
                                  if (sub.achievement != null && sub.achievement!.isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                    Icon(Icons.emoji_events, size: 14, color: Colors.amber.shade700),
                                    const SizedBox(width: 4),
                                    Text(sub.achievement!, style: TextStyle(fontSize: 13, color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
                                  ],
                                ],
                              ),
                              if (sub.description != null && sub.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  sub.description!,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (sub.reviewComment != null && sub.reviewComment!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.comment, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Advisor: ${sub.reviewComment}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
