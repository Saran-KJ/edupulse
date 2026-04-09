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
  String _selectedSemester = 'All';
  
  // Mapping for semester display
  static const List<String> _semesters = ['All', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'PEC', 'OEC', 'EEC'];
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _subjects = [];
  List<User> _facultyMembers = [];
  List<Map<String, dynamic>> _allocations = [];
  
  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Map to store selected faculty for each subject temporarily before saving
  final Map<String, User?> _selectedFacultyForSubject = {};

  @override
  void initState() {
    super.initState();
    if (widget.year != null) _selectedYear = widget.year!;
    if (widget.section != null) _selectedSection = widget.section!;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final faculty = await ApiService().getDepartmentFaculty(widget.dept);
      final subjects = await ApiService().getSubjects(
        semester: _selectedSemester == 'All' ? null : _selectedSemester
      );
      final allocations = await ApiService().getAllocations(widget.dept, _selectedYear, _selectedSection);
      
      List<Map<String, dynamic>> filteredSubjects = subjects;
      
      // Filter electives for semesters V, VI, VII based on HOD selections
      Set<String> selectedElectiveCodes = {};
      bool hasElectiveSemester = false;

      for (String sem in ['V', 'VI', 'VII']) {
         if (_selectedSemester == 'All' || _selectedSemester == sem) {
            hasElectiveSemester = true;
            try {
              final selections = await ApiService().getSubjectSelections(widget.dept, _selectedYear, _selectedSection, sem);
              selectedElectiveCodes.addAll(selections.map((s) => s['subject_code'].toString()));
            } catch (e) {
              // Ignore if no selections or error, just means no electives selected yet
            }
         }
      }

      if (hasElectiveSemester) {
         filteredSubjects = subjects.where((s) {
            final sem = s['semester']?.toString() ?? '';
            // DB stores numeric ("5","6","7") — match both numeric and roman forms
            if (sem == '5' || sem == '6' || sem == '7' ||
                sem == 'V' || sem == 'VI' || sem == 'VII') {
               final cat = s['category']?.toString().toUpperCase();
               if (cat == 'PEC' || cat == 'OEC' || cat == 'EEC') {
                  return selectedElectiveCodes.contains(s['subject_code'].toString());
               }
            }
            return true;
         }).toList();
      }
      
      setState(() {
        _facultyMembers = faculty;
        _subjects = filteredSubjects;
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
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildAllocationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by subject name or code...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  void _showManualAllocationDialog() {
    String dialogSemester = 'I';
    List<Map<String, dynamic>> dialogSubjects = [];
    Map<String, dynamic>? selectedSubject;
    User? selectedFaculty;
    int dialogYear = _selectedYear;
    String dialogSection = _selectedSection;
    final formKey = GlobalKey<FormState>();

    // Load subjects for default semester
    ApiService().getSubjects(semester: dialogSemester).then((subs) {
      dialogSubjects = subs;
    });

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
                  DropdownButtonFormField<String>(
                    initialValue: dialogSemester,
                    decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
                    items: _semesters.map((s) {
                      String label = s;
                      if (s != 'All' && s != 'PEC' && s != 'OEC' && s != 'EEC') {
                        label = 'Semester $s';
                      }
                      return DropdownMenuItem(value: s, child: Text(label));
                    }).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() {
                          dialogSemester = val;
                          selectedSubject = null;
                        });
                        final subs = await ApiService().getSubjects(
                          semester: val == 'All' ? null : val
                        );
                        setState(() => dialogSubjects = subs);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: selectedSubject,
                    decoration: const InputDecoration(labelText: 'Select Subject', border: OutlineInputBorder()),
                    isExpanded: true,
                    items: dialogSubjects.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text('${s['subject_code']} - ${s['subject_title']}', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) => setState(() => selectedSubject = val),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: dialogYear,
                    decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                    items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                    onChanged: (val) => setState(() => dialogYear = val!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: dialogSection,
                    decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                    items: ['A', 'B', 'C'].map((s) => DropdownMenuItem(value: s, child: Text('Section $s'))).toList(),
                    onChanged: (val) => setState(() => dialogSection = val!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<User>(
                    initialValue: selectedFaculty,
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
                if (formKey.currentState?.validate() == true && selectedSubject != null) {
                   Navigator.pop(context);
                   await _allocateFacultyManual(
                     selectedSubject!['subject_code'],
                     selectedSubject!['subject_title'],
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
              initialValue: _selectedYear,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedYear = val);
                  _loadData();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSection,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: ['A', 'B', 'C'].map((s) => DropdownMenuItem(value: s, child: Text('Sec $s', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedSection = val);
                  _loadData();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSemester,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Sem', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: _semesters.map((s) {
                String label = s;
                if (s != 'All' && s != 'PEC' && s != 'OEC' && s != 'EEC') {
                  label = 'Sem $s';
                }
                return DropdownMenuItem(value: s, child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)));
              }).toList(),
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
    final filtered = _searchQuery.isEmpty
        ? _subjects
        : _subjects.where((s) {
            final code = (s['subject_code'] ?? '').toString().toLowerCase();
            final title = (s['subject_title'] ?? '').toString().toLowerCase();
            return code.contains(_searchQuery) || title.contains(_searchQuery);
          }).toList();

    if (filtered.isEmpty) {
      return Center(child: Text(_subjects.isEmpty ? 'No subjects found for this semester.' : 'No results for "$_searchQuery".'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final subject = filtered[index];
        final subjectCode = subject['subject_code'];
        final subjectTitle = subject['subject_title'];

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
                          isExpanded: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Select Faculty',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _facultyMembers.map((f) => DropdownMenuItem(value: f, child: Text(f.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)))).toList(),
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
