import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final String dept;

  const SubjectSelectionScreen({super.key, required this.dept});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedYear = 3;
  String _selectedSection = 'A';
  String _selectedSemester = 'V';

  // Requirements: Show all 8 Semesters
  static const List<Map<String, dynamic>> _semestersWithYears = [
    {'sem': 'I', 'year': 1},
    {'sem': 'II', 'year': 1},
    {'sem': 'III', 'year': 2},
    {'sem': 'IV', 'year': 2},
    {'sem': 'V', 'year': 3},
    {'sem': 'VI', 'year': 3},
    {'sem': 'VII', 'year': 4},
    {'sem': 'VIII', 'year': 4},
  ];

  bool _isLoading = false;
  List<Map<String, dynamic>> _electiveSubjects = []; // PEC, OEC, EEC only
  Set<String> _selectedSubjectCodes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch all subjects across the curriculum
      final allSubjects = await ApiService().getSubjects();
      
      // Filter for PEC, OEC, EEC
      final electives = allSubjects.where((s) {
        final cat = s['category']?.toString().toUpperCase();
        return cat == 'PEC' || cat == 'OEC' || cat == 'EEC';
      }).toList();

      // 2. Fetch already selected subjects for this specific class
      final currentSelections = await ApiService().getSubjectSelections(
        widget.dept,
        _selectedYear,
        _selectedSection,
        _selectedSemester,
      );

      final selectedCodes = currentSelections.map((s) => s['subject_code'].toString()).toSet();

      setState(() {
        _electiveSubjects = electives;
        _selectedSubjectCodes = selectedCodes;
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

  Future<void> _saveSelections() async {
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> selectionsToSave = [];
      
      for (final subject in _electiveSubjects) {
        if (_selectedSubjectCodes.contains(subject['subject_code'])) {
          selectionsToSave.add({
            'dept': widget.dept,
            'year': _selectedYear,
            'section': _selectedSection,
            'semester': _selectedSemester,
            'subject_code': subject['subject_code'],
            'subject_title': subject['subject_title'],
            'category': subject['category'],
          });
        }
      }

      await ApiService().saveSubjectSelections(selectionsToSave);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject selections saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving selections: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Selection (Electives)'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterHeader(),
                Expanded(
                  child: _buildSubjectsList(),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Year 1')),
                DropdownMenuItem(value: 2, child: Text('Year 2')),
                DropdownMenuItem(value: 3, child: Text('Year 3')),
                DropdownMenuItem(value: 4, child: Text('Year 4')),
              ],
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
              value: _selectedSection,
              decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: ['A', 'B', 'C'].map((s) => DropdownMenuItem(value: s, child: Text('Sec $s'))).toList(),
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
              value: _selectedSemester,
              decoration: const InputDecoration(labelText: 'Sem', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: _semestersWithYears.map((s) {
                return DropdownMenuItem<String>(
                  value: s['sem'] as String, 
                  child: Text('Sem ${s['sem']}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSemester = val;
                    // Auto-update year based on semester
                    final matchingYear = _semestersWithYears.firstWhere((element) => element['sem'] == val)['year'] as int;
                    _selectedYear = matchingYear;
                  });
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList() {
    if (_electiveSubjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No PEC/OEC/EEC electives found for Semester $_selectedSemester.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _electiveSubjects.length,
      itemBuilder: (context, index) {
        final subject = _electiveSubjects[index];
        final subjectCode = subject['subject_code'] as String;
        final isSelected = _selectedSubjectCodes.contains(subjectCode);
        final category = subject['category'] ?? 'Elective';

        Color badgeColor = Colors.grey;
        if (category == 'PEC') badgeColor = Colors.blue.shade700;
        if (category == 'OEC') badgeColor = Colors.orange.shade700;
        if (category == 'EEC') badgeColor = Colors.green.shade700;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: CheckboxListTile(
            title: Text(subject['subject_title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(subjectCode),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            value: isSelected,
            activeColor: Colors.blue.shade800,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedSubjectCodes.add(subjectCode);
                } else {
                  _selectedSubjectCodes.remove(subjectCode);
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _electiveSubjects.isEmpty ? null : _saveSelections,
            icon: const Icon(Icons.save),
            label: const Text('Save Selections', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
