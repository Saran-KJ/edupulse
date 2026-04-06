import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ActivityManagementScreen extends StatefulWidget {
  final String dept; // Changed from deptId
  final int year;
  final String section;

  const ActivityManagementScreen({
    super.key,
    required this.dept,
    required this.year,
    required this.section,
  });

  @override
  State<ActivityManagementScreen> createState() => _ActivityManagementScreenState();
}

class _ActivityManagementScreenState extends State<ActivityManagementScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _studentActivities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getClassActivities(
        dept: widget.dept,
        year: widget.year,
        section: widget.section,
      );
      setState(() {
        _studentActivities = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AddActivityDialog(
        students: _studentActivities.map((e) => Student.fromJson(e['student'])).toList(),
        onSuccess: _fetchData,
      ),
    );
  }

  Future<void> _confirmDelete(int participationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteParticipation(participationId);
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showEditDialog(ActivityParticipation participation) {
    showDialog(
      context: context,
      builder: (context) => EditActivityDialog(
        participation: participation,
        onSuccess: _fetchData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Co/Extra-curricular Management'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddActivityDialog,
            tooltip: 'Entry Record',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _studentActivities.length,
                  itemBuilder: (context, index) {
                    final item = _studentActivities[index];
                    final student = Student.fromJson(item['student']);
                    final activities = (item['activities'] as List)
                        .map((e) => ActivityParticipation.fromJson(e))
                        .toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            student.name[0].toUpperCase(),
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(student.regNo),
                        children: [
                          if (activities.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No records found'),
                            )
                          else
                            ...activities.map((participation) {
                              final activity = participation.activity; // Access nested activity object
                              final activityName = activity != null ? activity.activityName : 'Activity ID: ${participation.activityId}';
                              final activityDate = activity != null ? activity.activityDate : 'Unknown Date';
                              final activityType = activity != null ? activity.activityType : 'Unknown Type';
                              final level = activity != null ? activity.level : 'N/A';
                              final description = activity != null ? activity.description : '';

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 2,
                                color: Colors.grey.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              activityName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              activityType,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            activityDate,
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(Icons.flag, size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            level ?? 'N/A',
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      Row(
                                        children: [
                                          const Text(
                                            'Role: ',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          Text(participation.role ?? "Participant"),
                                          const Spacer(),
                                          if (participation.achievement != null && participation.achievement!.isNotEmpty) ...[
                                            const Icon(Icons.emoji_events, size: 16, color: Colors.orange),
                                            const SizedBox(width: 4),
                                            Text(
                                              participation.achievement!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (description != null && description.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          description,
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showEditDialog(participation),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _confirmDelete(participation.participationId),
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class AddActivityDialog extends StatefulWidget {
  final List<Student> students;
  final VoidCallback onSuccess;

  const AddActivityDialog({super.key, required this.students, required this.onSuccess});

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  Student? _selectedStudent;
  final _activityNameController = TextEditingController();
  final _roleController = TextEditingController(); // Status
  final _achievementController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'Other';
  final List<String> _activityTypes = [
    'Sports', 'Hackathon', 'Workshop', 'Symposium', 
    'Seminar', 'Competition', 'Other'
  ];

  String _selectedLevel = 'College';
  final List<String> _levels = [
    'College', 'State', 'National', 'International'
  ];

  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  // Filter fields
  int? _selectedYear;
  int? _selectedSemester;
  final List<int> _years = [1, 2, 3, 4];
  final List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  // Filtered students based on year/semester
  List<Student> get _filteredStudents {
    return widget.students.where((student) {
      bool matchesYear = _selectedYear == null || student.year == _selectedYear;
      bool matchesSemester = _selectedSemester == null || student.semester == _selectedSemester;
      return matchesYear && matchesSemester;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Entry Co/Extra-curricular'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year Filter
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Filter by Year'),
                      value: _selectedYear,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Years')),
                        ..._years.map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedYear = val;
                          _selectedStudent = null; // Reset student selection
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Semester Filter
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Filter by Sem'),
                      value: _selectedSemester,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Sems')),
                        ..._semesters.map((s) => DropdownMenuItem(value: s, child: Text('Sem $s'))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedSemester = val;
                          _selectedStudent = null; // Reset student selection
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Student Selection
              DropdownButtonFormField<Student>(
                decoration: InputDecoration(
                  labelText: 'Select Student',
                  helperText: '${_filteredStudents.length} available',
                  isDense: true,
                ),
                isExpanded: true,
                items: _filteredStudents.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(
                      '${s.name} (${s.regNo}) - Y${s.year} S${s.semester}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedStudent = val),
                validator: (val) => val == null ? 'Please select a student' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _activityNameController,
                decoration: const InputDecoration(labelText: 'Activity Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Activity Type'),
                value: _selectedType,
                items: _activityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Level'),
                value: _selectedLevel,
                items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) => setState(() => _selectedLevel = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Status (Role)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _achievementController,
                decoration: const InputDecoration(labelText: 'Achievement (Optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text("${_selectedDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Create Activity first
      final activity = await ApiService().createActivity({
        'activity_name': _activityNameController.text,
        'activity_type': _selectedType,
        'level': _selectedLevel,
        'activity_date': _selectedDate.toIso8601String().split('T')[0],
        'description': _descriptionController.text,
      });

      // 2. Create Participation
      await ApiService().createParticipation({
        'activity_id': activity.activityId,
        'reg_no': _selectedStudent!.regNo, // Changed from student_id
        'role': _roleController.text,
        'achievement': _achievementController.text,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class EditActivityDialog extends StatefulWidget {
  final ActivityParticipation participation;
  final VoidCallback onSuccess;

  const EditActivityDialog({super.key, required this.participation, required this.onSuccess});

  @override
  State<EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<EditActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roleController;
  late TextEditingController _achievementController;
  late TextEditingController _activityNameController;
  late TextEditingController _descriptionController;

  String? _selectedType;
  final List<String> _activityTypes = [
    'Sports', 'Hackathon', 'Workshop', 'Symposium', 
    'Seminar', 'Competition', 'Other'
  ];

  String? _selectedLevel;
  final List<String> _levels = [
    'College', 'State', 'National', 'International'
  ];

  DateTime? _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _roleController = TextEditingController(text: widget.participation.role);
    _achievementController = TextEditingController(text: widget.participation.achievement);
    
    final activity = widget.participation.activity;
    _activityNameController = TextEditingController(text: activity?.activityName ?? '');
    _descriptionController = TextEditingController(text: activity?.description ?? '');
    _selectedType = activity?.activityType;
    _selectedLevel = activity?.level;
    if (activity?.activityDate != null) {
      try {
        _selectedDate = DateTime.parse(activity!.activityDate);
      } catch (_) {}
    }
    
    // Defaults if null
    if (_selectedType == null || !_activityTypes.contains(_selectedType)) {
      _selectedType = 'Other';
    }
    if (_selectedLevel == null || !_levels.contains(_selectedLevel)) {
      _selectedLevel = 'College';
    }
    _selectedDate ??= DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Co/Extra-curricular'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _activityNameController,
                decoration: const InputDecoration(labelText: 'Activity Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Activity Type'),
                value: _selectedType,
                items: _activityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Level'),
                value: _selectedLevel,
                items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) => setState(() => _selectedLevel = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Status (Role)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _achievementController,
                decoration: const InputDecoration(labelText: 'Achievement (Optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text("${_selectedDate?.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Update Activity
      if (widget.participation.activityId != 0) { // Should be valid ID
         await ApiService().updateActivity(widget.participation.activityId, {
          'activity_name': _activityNameController.text,
          'activity_type': _selectedType,
          'level': _selectedLevel,
          'activity_date': _selectedDate?.toIso8601String().split('T')[0],
          'description': _descriptionController.text,
        });
      }

      // 2. Update Participation
      await ApiService().updateParticipation(widget.participation.participationId, {
        'role': _roleController.text,
        'achievement': _achievementController.text,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
