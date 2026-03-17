import 'package:flutter/material.dart';
import '../models/mark_models.dart';
import '../services/api_service.dart';

class ViewMarksScreen extends StatefulWidget {
  final String dept; // Changed from deptId
  final int year;
  final String section;
  final int semester;

  const ViewMarksScreen({
    super.key,
    required this.dept,
    required this.year,
    required this.section,
    required this.semester,
  });

  @override
  State<ViewMarksScreen> createState() => _ViewMarksScreenState();
}

class _ViewMarksScreenState extends State<ViewMarksScreen> {
  bool _isLoading = true;
  Map<String, List<Mark>> _studentMarks = {};
  String? _error;
  late int _selectedSemester;

  @override
  void initState() {
    super.initState();
    _selectedSemester = widget.semester;
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final marksData = await ApiService().getClassMarks(
        dept: widget.dept,
        year: widget.year,
        section: widget.section,
        semester: _selectedSemester,
      );

      // Parse marks and group by student Reg No
      final Map<String, List<Mark>> groupedMarks = {};
      
      for (var data in marksData) {
        final mark = Mark.fromJson(data);
        if (!groupedMarks.containsKey(mark.regNo)) {
          groupedMarks[mark.regNo] = [];
        }
        groupedMarks[mark.regNo]!.add(mark);
      }

      setState(() {
        _studentMarks = groupedMarks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Marks'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<int>(
            value: _selectedSemester,
            dropdownColor: Colors.blue.shade800,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: Container(),
            items: List.generate(8, (index) => index + 1)
                .map((sem) => DropdownMenuItem(
                      value: sem,
                      child: Text('Sem $sem'),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedSemester = value);
                _loadMarks();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMarks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMarks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _studentMarks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No marks entered yet'),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView.builder(
                        itemCount: _studentMarks.length,
                        itemBuilder: (context, index) {
                          final regNo = _studentMarks.keys.elementAt(index);
                          final marks = _studentMarks[regNo]!;
                          final studentName = marks.first.studentName;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 3,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  studentName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Reg No: $regNo'),
                              children: marks.map((mark) => _buildMarkDetail(mark)).toList(),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildMarkDetail(Mark mark) {
    bool hasInternalMarks = !(
      (mark.assignment1 ?? 0) == 0 && (mark.assignment2 ?? 0) == 0 && (mark.assignment3 ?? 0) == 0 && 
      (mark.assignment4 ?? 0) == 0 && (mark.assignment5 ?? 0) == 0 &&
      (mark.slipTest1 ?? 0) == 0 && (mark.slipTest2 ?? 0) == 0 && (mark.slipTest3 ?? 0) == 0 && (mark.slipTest4 ?? 0) == 0 &&
      (mark.cia1 ?? 0) == 0 && (mark.cia2 ?? 0) == 0 && (mark.model ?? 0) == 0
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${mark.subjectCode} - ${mark.subjectTitle}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
          if (hasInternalMarks) ...[
            const SizedBox(height: 12),
            _buildScoreRow('Assignments', [
              mark.assignment1 ?? 0, mark.assignment2 ?? 0, mark.assignment3 ?? 0, 
              mark.assignment4 ?? 0, mark.assignment5 ?? 0
            ], 'A'),
            const SizedBox(height: 8),
            _buildScoreRow('Slip Tests', [
              mark.slipTest1 ?? 0, mark.slipTest2 ?? 0, mark.slipTest3 ?? 0, mark.slipTest4 ?? 0
            ], 'ST'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildSingleScore('CIA 1', mark.cia1 ?? 0)),
                Expanded(child: _buildSingleScore('CIA 2', mark.cia2 ?? 0)),
                Expanded(child: _buildSingleScore('Model', mark.model ?? 0)),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (mark.universityResultGrade != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mark.universityResultGrade == 'AREAR' ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: mark.universityResultGrade == 'AREAR' ? Colors.red.shade200 : Colors.green.shade200
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'University Result: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    mark.universityResultGrade!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: mark.universityResultGrade == 'AREAR' ? Colors.red : Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, List<int> scores, String prefix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: scores.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final score = entry.value;
            // Format to string
            final formattedScore = score.toString();
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text('$prefix$index', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(
                    formattedScore,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSingleScore(String label, int score) {
    final formattedScore = score.toString();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Center(
            child: Text(
              formattedScore,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
