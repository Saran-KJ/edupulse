import 'package:flutter/material.dart';
import '../models/models.dart';
import 'new_mark_entry_screen.dart';
import 'view_marks_screen.dart';

class StudentsMarkManagementScreen extends StatefulWidget {
  final List<Student> students;
  final String dept; // Changed from deptId
  final int year;
  final String section;

  const StudentsMarkManagementScreen({
    super.key,
    required this.students,
    required this.dept,
    required this.year,
    required this.section,
  });

  @override
  State<StudentsMarkManagementScreen> createState() =>
      _StudentsMarkManagementScreenState();
}

class _StudentsMarkManagementScreenState
    extends State<StudentsMarkManagementScreen> {
  
  void _viewMarks() {
    final semester = (widget.year * 2) - 1;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewMarksScreen(
          dept: widget.dept, // Changed from deptId
          year: widget.year,
          section: widget.section,
          semester: semester,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students List'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => _viewMarks(),
            tooltip: 'View Marks',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Students: ${widget.students.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 2,
                child: ListView.builder(
                  itemCount: widget.students.length,
                  itemBuilder: (context, index) {
                    final student = widget.students[index];
                    return ListTile(
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
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('Reg No: ${student.regNo}'),
                      trailing: Icon(
                        Icons.person,
                        color: Colors.blue.shade300,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectSelectionDialog(),
        backgroundColor: Colors.green.shade700,
        tooltip: 'Add Subjects & Enter Marks',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showSubjectSelectionDialog() {
    final semester = (widget.year * 2) - 1; // Calculate semester
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewMarkEntryScreen(
          students: widget.students,
          dept: widget.dept, // Changed from deptId
          year: widget.year,
          section: widget.section,
          semester: semester,
        ),
      ),
    );
  }
}
