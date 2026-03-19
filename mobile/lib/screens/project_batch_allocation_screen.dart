import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/project_dialogs.dart';

class ProjectBatchAllocationScreen extends StatefulWidget {
  final String dept;
  const ProjectBatchAllocationScreen({super.key, required this.dept});

  @override
  State<ProjectBatchAllocationScreen> createState() => _ProjectBatchAllocationScreenState();
}

class _ProjectBatchAllocationScreenState extends State<ProjectBatchAllocationScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _currentUser;
  int _selectedYear = 4;

  String _selectedSection = 'A';
  
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _coordinators = [];
  List<Map<String, dynamic>> _faculty = [];


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadCurrentUser();
    await _loadBatches();
    await _loadCoordinator();
    await _loadFaculty();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await ApiService().getCurrentUser();
      setState(() => _currentUser = user.toJson());
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }


  Future<void> _loadFaculty() async {
    try {
      final faculty = await ApiService().getDepartmentFaculty(widget.dept);
      setState(() {
        _faculty = faculty.map((f) => {'user_id': f.userId, 'name': f.name}).toList();
      });
    } catch (e) {
      debugPrint('Error loading faculty: $e');
    }
  }

  Future<void> _loadCoordinator() async {
    try {
      final coordinators = await ApiService().getProjectCoordinators(widget.dept);
      setState(() {
        _coordinators = coordinators.where((c) => c['year'] == _selectedYear).toList();
      });
    } catch (e) {
      debugPrint('Error loading coordinators: $e');
    }
  }



  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    try {
      final batches = await ApiService().getProjectBatches(
        dept: widget.dept,
        year: _selectedYear,
        section: _selectedSection,
      );
      setState(() => _batches = batches);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading batches: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onYearChanged(int? year) {
    if (year != null) {
      setState(() => _selectedYear = year);
      _loadData();
    }
  }

  void _onSectionChanged(String? section) {
    if (section != null) {
      setState(() => _selectedSection = section);
      _loadBatches();
    }
  }


  void _openCreateBatchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateBatchDialog(
        dept: widget.dept,
        year: _selectedYear,
        section: _selectedSection,
        onBatchCreated: () {
          Navigator.pop(ctx);
          _loadBatches();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? role = _currentUser?['role']?.toString().toLowerCase();
    final bool isHODOrAdmin = role == 'hod' || role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Batches'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          _buildCoordinatorHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _batches.isEmpty
                    ? Center(child: Text('No batches found for Year $_selectedYear, Section $_selectedSection'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _batches.length,
                        itemBuilder: (ctx, index) {
                          final batch = _batches[index];
                          final students = batch['students'] as List<dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Batch #${batch['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                                      Chip(
                                        avatar: const Icon(Icons.person, size: 16),
                                        label: Text(batch['guide_name'] ?? 'Unknown Guide'),
                                        backgroundColor: Colors.blue.shade50,
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  const Text('Students:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  ...students.map((s) => Row(
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text('${s['reg_no']} - ${s['name']}'),
                                    ],
                                  )),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Reviewer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                          Text(batch['reviewer_name'] ?? 'Not Assigned', style: TextStyle(color: batch['reviewer_name'] == null ? Colors.orange : Colors.black)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (_coordinators.any((c) => c['faculty_id'] == _currentUser?['user_id'])) // Only assigned coordinators can assign reviewers on this screen
                                            IconButton(
                                              onPressed: () => _openAssignReviewerDialog(batch),
                                              icon: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                                              tooltip: 'Assign Reviewer',
                                            ),
                                          if (_currentUser?['user_id'] == batch['reviewer_id'] || _coordinators.any((c) => c['faculty_id'] == _currentUser?['user_id']))
                                            OutlinedButton.icon(
                                              onPressed: () => _openAddReviewDialog(batch),
                                              icon: const Icon(Icons.rate_review),
                                              label: const Text('Add Review'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.blue.shade800,
                                                side: BorderSide(color: Colors.blue.shade800),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),

                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateBatchDialog,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Batch'),
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: const [
                DropdownMenuItem(value: 3, child: Text('Year 3')),
                DropdownMenuItem(value: 4, child: Text('Year 4')),
              ],
              onChanged: _onYearChanged,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSection,
              decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: ['A', 'B', 'C'].map((s) => DropdownMenuItem(value: s, child: Text('Section $s'))).toList(),
              onChanged: _onSectionChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatorHeader() {
    final String? role = _currentUser?['role']?.toString().toLowerCase();
    final bool isHODOrAdmin = role == 'hod' || role == 'admin';
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.blue.shade900),
              const SizedBox(width: 8),
              Text(
                'Project Coordinators (Year $_selectedYear)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
              const Spacer(),
              if (isHODOrAdmin && _coordinators.length < 2)
                ElevatedButton.icon(
                  onPressed: () => _openAssignCoordinatorDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Assign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_coordinators.isEmpty)
            const Text('No coordinator assigned for this year', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _coordinators.map((coord) {
                return GestureDetector(
                  onTap: isHODOrAdmin ? () => _openAssignCoordinatorDialog(
                    coordId: coord['id'],
                    initialFacultyId: coord['faculty_id'],
                  ) : null,
                  child: Tooltip(
                    message: isHODOrAdmin ? 'Click to edit coordinator' : '',
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(coord['faculty_name'][0], style: const TextStyle(fontSize: 10)),
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(coord['faculty_name']),
                          if (isHODOrAdmin) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 14, color: Colors.blue.shade700),
                          ],
                        ],
                      ),
                      onDeleted: isHODOrAdmin ? () => _deleteCoordinator(coord['id']) : null,
                      deleteIconColor: Colors.red.shade400,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.blue.shade200),
                    ),
                  ),
                );
              }).toList(),

            ),
        ],
      ),
    );
  }

  Future<void> _deleteCoordinator(int id) async {
    try {
      await ApiService().deleteProjectCoordinator(id);
      _loadCoordinator();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coordinator removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }


  void _openAssignCoordinatorDialog({int? coordId, int? initialFacultyId}) {
    int? selectedFacultyId = initialFacultyId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(coordId == null ? 'Assign Project Coordinator' : 'Edit Project Coordinator'),
          content: DropdownButtonFormField<int>(
            value: selectedFacultyId,
            decoration: const InputDecoration(labelText: 'Select Faculty', border: OutlineInputBorder()),
            items: _faculty.map((f) => DropdownMenuItem(value: f['user_id'] as int, child: Text(f['name']))).toList(),
            onChanged: (val) => setDialogState(() => selectedFacultyId = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedFacultyId == null ? null : () async {
                try {
                  if (coordId == null) {
                    await ApiService().assignProjectCoordinator(
                      facultyId: selectedFacultyId!,
                      dept: widget.dept,
                      year: _selectedYear,
                    );
                  } else {
                    await ApiService().updateProjectCoordinator(
                      coordId,
                      facultyId: selectedFacultyId!,
                      dept: widget.dept,
                      year: _selectedYear,
                    );
                  }
                  Navigator.pop(context);
                  _loadCoordinator();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: Text(coordId == null ? 'Assign' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }


  void _openAssignReviewerDialog(Map<String, dynamic> batch) {
    int? selectedReviewerId = batch['reviewer_id'];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Reviewer - Batch #${batch['id']}'),
          content: DropdownButtonFormField<int>(
            value: selectedReviewerId,
            decoration: const InputDecoration(labelText: 'Select Faculty', border: OutlineInputBorder()),
            items: _faculty.map((f) => DropdownMenuItem(value: f['user_id'] as int, child: Text(f['name']))).toList(),
            onChanged: (val) => setDialogState(() => selectedReviewerId = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedReviewerId == null ? null : () async {
                try {
                  await ApiService().assignBatchReviewer(batch['id'], selectedReviewerId!);
                  Navigator.pop(context);
                  _loadBatches();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }


  void _openAddReviewDialog(Map<String, dynamic> batch) {
    showDialog(
      context: context,
      builder: (ctx) => AddReviewDialog(
        batch: batch,
        onReviewAdded: _loadBatches,
      ),
    );
  }
}

class _CreateBatchDialog extends StatefulWidget {
  final String dept;
  final int year;
  final String section;
  final VoidCallback onBatchCreated;

  const _CreateBatchDialog({
    required this.dept,
    required this.year,
    required this.section,
    required this.onBatchCreated,
  });

  @override
  State<_CreateBatchDialog> createState() => _CreateBatchDialogState();
}

class _CreateBatchDialogState extends State<_CreateBatchDialog> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _faculty = [];
  List<Map<String, dynamic>> _students = [];
  
  int? _selectedGuideId;
  Set<String> _selectedStudentRegNos = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final faculty = await ApiService().getDepartmentFaculty(widget.dept);
      final students = await ApiService().getStudents(
        dept: widget.dept,
        year: widget.year,
        section: widget.section,
      );

      // Fetch all existing batches for this class to filter out already assigned students
      final existingBatches = await ApiService().getProjectBatches(
        dept: widget.dept,
        year: widget.year,
        section: widget.section,
      );

      Set<String> assignedRegNos = {};
      for (final b in existingBatches) {
        final stList = b['students'] as List<dynamic>;
        for (final s in stList) {
          if (s['reg_no'] != null) {
            assignedRegNos.add(s['reg_no'] as String);
          }
        }
      }

      final availableStudentsList = students.where((s) => !assignedRegNos.contains(s.regNo)).toList();

      setState(() {
        _faculty = faculty.map((f) => {'user_id': f.userId, 'name': f.name, 'reg_no': f.regNo}).toList();
        _students = availableStudentsList.map((s) => {'student_id': s.studentId, 'name': s.name, 'reg_no': s.regNo}).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBatch() async {
    if (_selectedGuideId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a guide')));
      return;
    }
    if (_selectedStudentRegNos.isEmpty || _selectedStudentRegNos.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select 1 to 4 students')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService().createProjectBatch(
        guideId: _selectedGuideId!,
        dept: widget.dept,
        year: widget.year,
        section: widget.section,
        studentRegNos: _selectedStudentRegNos.toList(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch created successfully!'), backgroundColor: Colors.green));
        widget.onBatchCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
    }

    return AlertDialog(
      title: const Text('Create Project Batch'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Select Guide', border: OutlineInputBorder()),
              value: _selectedGuideId,
              items: _faculty.map((f) => DropdownMenuItem(value: f['user_id'] as int, child: Text(f['name']))).toList(),
              onChanged: (val) => setState(() => _selectedGuideId = val),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Students (1-4)', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_selectedStudentRegNos.length}/4', style: TextStyle(color: _selectedStudentRegNos.length > 4 ? Colors.red : Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            _students.isEmpty
                ? const Text('No unassigned students available', style: TextStyle(color: Colors.red))
                : Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _students.length,
                      itemBuilder: (ctx, idx) {
                        final s = _students[idx];
                        final regNo = s['reg_no'] as String;
                        final isSelected = _selectedStudentRegNos.contains(regNo);
                        return CheckboxListTile(
                          title: Text(s['name']),
                          subtitle: Text(regNo),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                if (_selectedStudentRegNos.length < 4) {
                                  _selectedStudentRegNos.add(regNo);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 4 students allowed')));
                                }
                              } else {
                                _selectedStudentRegNos.remove(regNo);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _students.isEmpty ? null : _createBatch, 
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
          child: const Text('Create')
        ),
      ],
    );
  }
}
