import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';

class QuizStatusScreen extends StatefulWidget {
  final int quizId;
  final String subjectTitle;

  const QuizStatusScreen({
    super.key,
    required this.quizId,
    required this.subjectTitle,
  });

  @override
  State<QuizStatusScreen> createState() => _QuizStatusScreenState();
}

class _QuizStatusScreenState extends State<QuizStatusScreen> {
  late Future<QuizStatusResponse> _statusFuture;
  String _searchQuery = '';
  String _sortOrder = 'name'; // 'name' or 'score'

  @override
  void initState() {
    super.initState();
    _statusFuture = ApiService().getQuizStatus(widget.quizId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Quiz Status',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<QuizStatusResponse>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _statusFuture = ApiService().getQuizStatus(widget.quizId);
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No status data available'));
          }

          final status = snapshot.data!;
          final filteredStudents = status.students.where((s) {
            final nameMatch = s.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
            final regNoMatch = s.regNo.toLowerCase().contains(_searchQuery.toLowerCase());
            return nameMatch || regNoMatch;
          }).toList();

          // Sort
          if (_sortOrder == 'name') {
            filteredStudents.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
          } else if (_sortOrder == 'score') {
            filteredStudents.sort((a, b) => (b.score ?? -1.0).compareTo(a.score ?? -1.0));
          }

          return Column(
            children: [
              _buildSummaryHeader(status),
              _buildSearchAndFilter(),
              Expanded(
                child: filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          return _buildStudentCard(filteredStudents[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(QuizStatusResponse status) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subjectTitle,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryItem('Total', status.totalStudents.toString(), Colors.blue.shade100),
              _buildSummaryItem('Completed', status.completedCount.toString(), Colors.green.shade100),
              _buildSummaryItem('Pending', status.pendingCount.toString(), Colors.orange.shade100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search student...',
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
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.sort_rounded),
              onSelected: (v) => setState(() => _sortOrder = v),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
                const PopupMenuItem(value: 'score', child: Text('Sort by Score')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentQuizStatus student) {
    final bool isCompleted = student.status == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isCompleted ? Colors.green.shade50 : Colors.grey.shade100,
          child: Text(
            (student.name ?? student.regNo)[0].toUpperCase(),
            style: TextStyle(
              color: isCompleted ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name ?? 'Unknown',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          student.regNo,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.status,
                style: TextStyle(
                  color: isCompleted ? Colors.green : Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isCompleted && student.score != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${student.score!.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No matching students found',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
