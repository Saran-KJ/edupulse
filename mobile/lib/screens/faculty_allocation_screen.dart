import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class FacultyAllocationScreen extends StatefulWidget {
  final String dept;
  final int? year; // Optional initial value
  final String? section; // Optional initial value

  const FacultyAllocationScreen({
    super.key,
    required this.dept,
    this.year,
    this.section,
  });

  @override
  State<FacultyAllocationScreen> createState() => _FacultyAllocationScreenState();
}

class _FacultyAllocationScreenState extends State<FacultyAllocationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedYear = 1;
  String _selectedSection = 'A';
  int _selectedSemester = 1;
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _subjects = [];
  List<User> _facultyMembers = [];
  List<Map<String, dynamic>> _allocations = [];
  
  // Map to store selected faculty for each subject temporarily before saving
  final Map<String, User?> _selectedFacultyForSubject = {};

  @override
  void initState() {
    super.initState();
    if (widget.year != null) _selectedYear = widget.year!;
    if (widget.section != null) _selectedSection = widget.section!;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final faculty = await ApiService().getDepartmentFaculty(widget.dept);
      final subjects = await ApiService().getDepartmentSubjects(widget.dept, _selectedSemester);
      final allocations = await ApiService().getAllocations(widget.dept, _selectedYear, _selectedSection);
      
      setState(() {
        _facultyMembers = faculty;
        _subjects = subjects;
        _allocations = allocations;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _allocateFaculty(String subjectCode, String subjectTitle, User faculty) async {
    // Check if already allocated
    final existing = _allocations.firstWhere(
      (a) => a['subject_code'] == subjectCode,
      orElse: () => {},
    );

    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty already allocated. Remove existing allocation first.')),
      );
      return;
    }

    try {
      await ApiService().createAllocation({
        'dept': widget.dept,
        'year': _selectedYear,
        'section': _selectedSection,
        'subject_code': subjectCode,
        'subject_title': subjectTitle,
        'faculty_id': faculty.userId,
        'faculty_name': faculty.name,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty allocated successfully')),
      );
      _loadData(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error allocating faculty: $e')),
      );
    }
  }

  Future<void> _removeAllocation(int id) async {
    try {
      await ApiService().deleteAllocation(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allocation removed')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing allocation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Allocation'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildAllocationList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualAllocationDialog,
        label: const Text('Add Allocation'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue.shade800,
      ),
    );
  }

  void _showManualAllocationDialog() {
    final titleController = TextEditingController();
    final codeController = TextEditingController();
    User? selectedFaculty;
    int dialogYear = _selectedYear;
    String dialogSection = _selectedSection;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manual Allocation'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Subject Title', border: OutlineInputBorder()),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Subject Code', border: OutlineInputBorder()),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: dialogYear,
                    decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                    items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                    onChanged: (val) => setState(() => dialogYear = val!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: dialogSection,
                    decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                    items: ['A', 'B', 'C'].map((s) => DropdownMenuItem(value: s, child: Text('Section $s'))).toList(),
                    onChanged: (val) => setState(() => dialogSection = val!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<User>(
                    value: selectedFaculty,
                    decoration: const InputDecoration(labelText: 'Select Faculty', border: OutlineInputBorder()),
                    items: _facultyMembers.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                    onChanged: (val) => setState(() => selectedFaculty = val),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() == true) {
                   Navigator.pop(context);
                   await _allocateFacultyManual(
                     codeController.text,
                     titleController.text,
                     selectedFaculty!,
                     dialogYear,
                     dialogSection
                   );
                }
              },
              child: const Text('Allocate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _allocateFacultyManual(String code, String title, User faculty, int year, String section) async {
      try {
      await ApiService().createAllocation({
        'dept': widget.dept,
        'year': year,
        'section': section,
        'subject_code': code,
        'subject_title': title,
        'faculty_id': faculty.userId,
        'faculty_name': faculty.name,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty allocated successfully')),
      );
      _loadData(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error allocating faculty: $e')),
      );
    }
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
              items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedYear = val);
                  _loadData();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSection,
              decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
              items: ['A', 'B', 'C'].map((s) => DropdownMenuItem(value: s, child: Text('Section $s'))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedSection = val);
                  _loadData();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedSemester,
              decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
              items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text('Sem $s'))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedSemester = val);
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationList() {
    if (_subjects.isEmpty) {
      return const Center(child: Text('No subjects found for this semester.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        final subjectCode = subject['subject_code'];
        final subjectTitle = subject['subject_name']; // Note: API returns subject_name

        // Check if allocated
        final allocation = _allocations.firstWhere(
          (a) => a['subject_code'] == subjectCode,
          orElse: () => {},
        );
        final isAllocated = allocation.isNotEmpty;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subjectCode,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subjectTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (isAllocated)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.green),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Allocated to:',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              Text(
                                allocation['faculty_name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Remove Allocation',
                        onPressed: () => _removeAllocation(allocation['id']),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<User>(
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Select Faculty',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _facultyMembers.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _allocateFaculty(subjectCode, subjectTitle, val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
