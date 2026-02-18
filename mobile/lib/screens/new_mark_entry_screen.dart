import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/mark_models.dart';
import '../services/api_service.dart';

class NewMarkEntryScreen extends StatefulWidget {
  final List<Student> students;
  final String dept; // Changed from deptId
  final int year;
  final String section;
  final int semester;
  final String? subjectCode;
  final String? subjectTitle;

  const NewMarkEntryScreen({
    super.key,
    required this.students,
    required this.dept,
    required this.year,
    required this.section,
    required this.semester,
    this.subjectCode,
    this.subjectTitle,
  });

  @override
  State<NewMarkEntryScreen> createState() => _NewMarkEntryScreenState();
}

class _NewMarkEntryScreenState extends State<NewMarkEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCodeController = TextEditingController();
  final _subjectTitleController = TextEditingController();
  
  // Map to store controllers for each student's marks
  final Map<int, Map<String, TextEditingController>> _studentControllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.subjectCode != null) _subjectCodeController.text = widget.subjectCode!;
    if (widget.subjectTitle != null) _subjectTitleController.text = widget.subjectTitle!;
    _initializeControllers();
    _loadExistingMarks();
  }

  void _initializeControllers() {
    for (var student in widget.students) {
      _studentControllers[student.studentId] = {
        'a1': TextEditingController(), 'a2': TextEditingController(),
        'a3': TextEditingController(), 'a4': TextEditingController(),
        'a5': TextEditingController(),
        'st1': TextEditingController(), 'st2': TextEditingController(),
        'st3': TextEditingController(), 'st4': TextEditingController(),
        'cia1': TextEditingController(), 'cia2': TextEditingController(),
        'model': TextEditingController(),
        'uni': TextEditingController(),
      };
    }
  }

  Future<void> _loadExistingMarks() async {
    try {
      final marksData = await ApiService().getClassMarks(
        dept: widget.dept,
        year: widget.year,
        section: widget.section,
        semester: widget.semester,
        subjectCode: widget.subjectCode,
      );

      if (marksData.isNotEmpty) {
        // Assuming all marks are for the same subject for this entry session
        // We take the subject from the first mark found
        final firstMark = Mark.fromJson(marksData.first);
        _subjectCodeController.text = firstMark.subjectCode;
        _subjectTitleController.text = firstMark.subjectTitle;

        for (var data in marksData) {
          final mark = Mark.fromJson(data);
          // Find student by regNo
          final student = widget.students.firstWhere(
            (s) => s.regNo == mark.regNo,
            orElse: () => widget.students.first, // Fallback, should not happen if data consistent
          );
          
          if (_studentControllers.containsKey(student.studentId)) {
            final ctrls = _studentControllers[student.studentId]!;
            ctrls['a1']!.text = mark.assignment1 == 0 ? '' : mark.assignment1.toString();
            ctrls['a2']!.text = mark.assignment2 == 0 ? '' : mark.assignment2.toString();
            ctrls['a3']!.text = mark.assignment3 == 0 ? '' : mark.assignment3.toString();
            ctrls['a4']!.text = mark.assignment4 == 0 ? '' : mark.assignment4.toString();
            ctrls['a5']!.text = mark.assignment5 == 0 ? '' : mark.assignment5.toString();
            ctrls['st1']!.text = mark.slipTest1 == 0 ? '' : mark.slipTest1.toString();
            ctrls['st2']!.text = mark.slipTest2 == 0 ? '' : mark.slipTest2.toString();
            ctrls['st3']!.text = mark.slipTest3 == 0 ? '' : mark.slipTest3.toString();
            ctrls['st4']!.text = mark.slipTest4 == 0 ? '' : mark.slipTest4.toString();
            ctrls['cia1']!.text = mark.cia1 == 0 ? '' : mark.cia1.toString();
            ctrls['cia2']!.text = mark.cia2 == 0 ? '' : mark.cia2.toString();
            ctrls['model']!.text = mark.model == 0 ? '' : mark.model.toString();
            ctrls['uni']!.text = mark.universityResultGrade ?? '';
          }
        }
        setState(() {}); // Refresh UI
      }
    } catch (e) {

      // Non-blocking, just don't pre-fill
    }
  }

  @override
  void dispose() {
    _subjectCodeController.dispose();
    _subjectTitleController.dispose();
    for (var controllers in _studentControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _submitMarks() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final List<Map<String, dynamic>> marksList = [];

      for (var student in widget.students) {
        final controllers = _studentControllers[student.studentId]!;
        
        // Only add if at least one mark is entered or if we want to create a record for everyone
        // For now, we create for everyone to ensure consistency
        
        final markCreate = MarkCreate(
          regNo: student.regNo,
          studentName: student.name,
          dept: widget.dept, // Added dept
          year: widget.year,
          section: widget.section,
          semester: widget.semester,
          subjectCode: _subjectCodeController.text.trim(),
          subjectTitle: _subjectTitleController.text.trim(),
          assignment1: double.tryParse(controllers['a1']!.text) ?? 0.0,
          assignment2: double.tryParse(controllers['a2']!.text) ?? 0.0,
          assignment3: double.tryParse(controllers['a3']!.text) ?? 0.0,
          assignment4: double.tryParse(controllers['a4']!.text) ?? 0.0,
          assignment5: double.tryParse(controllers['a5']!.text) ?? 0.0,
          slipTest1: double.tryParse(controllers['st1']!.text) ?? 0.0,
          slipTest2: double.tryParse(controllers['st2']!.text) ?? 0.0,
          slipTest3: double.tryParse(controllers['st3']!.text) ?? 0.0,
          slipTest4: double.tryParse(controllers['st4']!.text) ?? 0.0,
          cia1: double.tryParse(controllers['cia1']!.text) ?? 0.0,
          cia2: double.tryParse(controllers['cia2']!.text) ?? 0.0,
          model: double.tryParse(controllers['model']!.text) ?? 0.0,
          universityResultGrade: controllers['uni']!.text.trim().isEmpty 
              ? null 
              : controllers['uni']!.text.trim(),
        );

        marksList.add(markCreate.toJson());
      }

      await ApiService().submitBulkMarksNew(marksList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving marks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Marks - Sem ${widget.semester}'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _submitMarks,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSubjectHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.students.length,
                itemBuilder: (context, index) {
                  return _buildStudentCard(widget.students[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitMarks,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Save All Marks', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildSubjectHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _subjectCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Code',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _subjectTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Title',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    final controllers = _studentControllers[student.studentId]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            student.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(student.regNo),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assignments (10 marks each)', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMarkInput(controllers['a1']!, 'A1', 10),
                    const SizedBox(width: 8),
                    _buildMarkInput(controllers['a2']!, 'A2', 10),
                    const SizedBox(width: 8),
                    _buildMarkInput(controllers['a3']!, 'A3', 10),
                    const SizedBox(width: 8),
                    _buildMarkInput(controllers['a4']!, 'A4', 10),
                    const SizedBox(width: 8),
                    _buildMarkInput(controllers['a5']!, 'A5', 10),
                  ],
                ),
                const SizedBox(height: 16),
                
                const Text('Slip Tests (20 marks each)', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMarkInput(controllers['st1']!, 'ST1', 20),
                    const SizedBox(width: 8),
                    _buildMarkInput(controllers['st2']!, 'ST2', 20),
                    const SizedBox(width: 8),
                    _buildMarkInput(controllers['st3']!, 'ST3', 20),
                    const SizedBox(width: 8),
                    _buildMarkInput(controllers['st4']!, 'ST4', 20),
                  ],
                ),
                const SizedBox(height: 16),
                
                const Text('CIA (60 marks) & Model (100 marks)', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMarkInput(controllers['cia1']!, 'CIA 1', 60),
                    const SizedBox(width: 8),
                    _buildMarkInput(controllers['cia2']!, 'CIA 2', 60),
                    const SizedBox(width: 8),
                    _buildMarkInput(controllers['model']!, 'Model', 100),
                  ],
                ),
                const SizedBox(height: 16),
                
                const Text('University Result', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: controllers['uni']!.text,
                    decoration: const InputDecoration(
                      labelText: 'Grade',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Select')),
                      DropdownMenuItem(value: 'O', child: Text('O')),
                      DropdownMenuItem(value: 'A+', child: Text('A+')),
                      DropdownMenuItem(value: 'A', child: Text('A')),
                      DropdownMenuItem(value: 'B+', child: Text('B+')),
                      DropdownMenuItem(value: 'B', child: Text('B')),
                      DropdownMenuItem(value: 'C', child: Text('C')),
                      DropdownMenuItem(value: 'ARREAR', child: Text('ARREAR')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controllers['uni']!.text = value;
                      }
                    },
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkInput(TextEditingController controller, String label, double max) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return null;
          final numValue = double.tryParse(value);
          if (numValue == null) return 'Invalid';
          if (numValue < 0 || numValue > max) return 'Max $max';
          return null;
        },
      ),
    );
  }
}
