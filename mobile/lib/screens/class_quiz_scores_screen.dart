import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';

class ClassQuizScoresScreen extends StatefulWidget {
  final String dept;
  final int year;
  final String section;
  final String subjectCode;
  final String subjectTitle;

  const ClassQuizScoresScreen({
    super.key,
    required this.dept,
    required this.year,
    required this.section,
    required this.subjectCode,
    required this.subjectTitle,
  });

  @override
  State<ClassQuizScoresScreen> createState() => _ClassQuizScoresScreenState();
}

class _ClassQuizScoresScreenState extends State<ClassQuizScoresScreen> {
  late Future<ClassQuizScoresResponse> _scoresFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scoresFuture = ApiService().getClassQuizScores(
      dept: widget.dept,
      year: widget.year,
      section: widget.section,
      subjectCode: widget.subjectCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Quiz Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchField(),
          Expanded(
            child: FutureBuilder<ClassQuizScoresResponse>(
              future: _scoresFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text('Error loading scores: ${snapshot.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {
                              _scoresFuture = ApiService().getClassQuizScores(
                                dept: widget.dept,
                                year: widget.year,
                                section: widget.section,
                                subjectCode: widget.subjectCode,
                              );
                            }),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No data found'));
                }

                final data = snapshot.data!;
                final filteredStudents = data.students.where((s) {
                  final query = _searchQuery.toLowerCase();
                  return (s.name?.toLowerCase().contains(query) ?? false) || 
                         s.regNo.toLowerCase().contains(query);
                }).toList();

                if (filteredStudents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No students matching "$_searchQuery"', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                return _buildScoresTable(filteredStudents);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subjectTitle,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.dept} - Year ${widget.year} ${widget.section}',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search by Name or Reg No...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildScoresTable(List<StudentUnitScore> students) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
          columns: [
            DataColumn(label: Text('Student', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13))),
            DataColumn(label: Text('U1', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13))),
            DataColumn(label: Text('U2', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13))),
            DataColumn(label: Text('U3', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13))),
            DataColumn(label: Text('U4', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13))),
            DataColumn(label: Text('U5', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13))),
          ],
          rows: students.map<DataRow>((s) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
                        Text(s.regNo, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                _buildScoreCell(s.scores['1']),
                _buildScoreCell(s.scores['2']),
                _buildScoreCell(s.scores['3']),
                _buildScoreCell(s.scores['4']),
                _buildScoreCell(s.scores['5']),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  DataCell _buildScoreCell(dynamic score) {
    if (score == null) {
      return const DataCell(Center(child: Text('—', style: TextStyle(color: Colors.grey))));
    }
    
    final double val = score.toDouble();
    Color color = Colors.green;
    if (val < 50) {
      color = Colors.red;
    } else if (val < 75) color = Colors.orange;

    return DataCell(
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            val.toStringAsFixed(0),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
