import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CgpaScreen extends StatefulWidget {
  final String regNo;
  const CgpaScreen({super.key, required this.regNo});

  @override
  State<CgpaScreen> createState() => _CgpaScreenState();
}

class _CgpaScreenState extends State<CgpaScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _cgpaData;
  bool _isLoading = true;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadCgpa();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadCgpa() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService().getCgpa(widget.regNo);
      setState(() { _cgpaData = data; _isLoading = false; });
      _animController.forward();
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _cgpaColor(double cgpa) {
    if (cgpa >= 9.0) return const Color(0xFF00B894);
    if (cgpa >= 8.0) return const Color(0xFF0984E3);
    if (cgpa >= 7.0) return const Color(0xFFFDAB3A);
    if (cgpa >= 6.0) return const Color(0xFFE17055);
    return const Color(0xFFD63031);
  }

  String _cgpaLabel(double cgpa) {
    if (cgpa >= 9.0) return 'Outstanding';
    if (cgpa >= 8.0) return 'Excellent';
    if (cgpa >= 7.0) return 'Good';
    if (cgpa >= 6.0) return 'Average';
    if (cgpa > 0) return 'Below Average';
    return 'No Data';
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'O': return const Color(0xFF00B894);
      case 'A+': return const Color(0xFF0984E3);
      case 'A': return const Color(0xFF6C5CE7);
      case 'B+': return const Color(0xFFFDAB3A);
      case 'B': return const Color(0xFFE17055);
      case 'C': return Colors.orange;
      default: return const Color(0xFFD63031);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        title: const Text('CGPA Calculator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A2535),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadCgpa,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
          : _error != null
              ? _buildError()
              : FadeTransition(opacity: _fadeAnim, child: _buildContent()),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text('Failed to load CGPA', style: TextStyle(color: Colors.white70)),
          TextButton(onPressed: _loadCgpa, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final cgpa = (_cgpaData?['overall_cgpa'] ?? 0.0).toDouble();
    final totalCredits = (_cgpaData?['total_credits_earned'] ?? 0.0).toDouble();
    final semesters = List<Map<String, dynamic>>.from(_cgpaData?['semesters'] ?? []);
    final gradeDist = Map<String, dynamic>.from(_cgpaData?['grade_distribution'] ?? {});

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // CGPA Hero Card
        _buildCgpaHero(cgpa, totalCredits),
        const SizedBox(height: 16),
        // Grade Distribution
        if (gradeDist.isNotEmpty) ...[
          _buildGradeDistribution(gradeDist),
          const SizedBox(height: 16),
        ],
        // Semester-wise GPA
        if (semesters.isEmpty)
          _buildEmptyState()
        else
          ...semesters.map((sem) => _buildSemesterCard(sem)),
      ],
    );
  }

  Widget _buildCgpaHero(double cgpa, double totalCredits) {
    final color = _cgpaColor(cgpa);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), const Color(0xFF1A2535)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Overall CGPA', style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: cgpa),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) => Text(
              val.toStringAsFixed(2),
              style: TextStyle(
                color: color, fontSize: 64, fontWeight: FontWeight.bold,
                shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 12)],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(_cgpaLabel(cgpa), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip(Icons.credit_card, '${totalCredits.toStringAsFixed(0)} Credits Earned'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.school, 'Out of 10.0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution(Map<String, dynamic> gradeDist) {
    final gradeOrder = ['O', 'A+', 'A', 'B+', 'B', 'C', 'U', 'AREAR'];
    final sortedGrades = gradeOrder.where((g) => gradeDist.containsKey(g)).toList();
    final total = gradeDist.values.fold<int>(0, (a, b) => a + (b as int));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grade Distribution', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ...sortedGrades.map((grade) {
            final count = gradeDist[grade] as int;
            final pct = count / total;
            final color = _gradeColor(grade);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(grade, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$count', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSemesterCard(Map<String, dynamic> sem) {
    final gpa = (sem['gpa'] ?? 0.0).toDouble();
    final color = _cgpaColor(gpa);
    final subjects = List<Map<String, dynamic>>.from(sem['subjects'] ?? []);
    final arrears = sem['arrears'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        collapsedIconColor: Colors.white38,
        iconColor: color,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(sem['semester_label'] ?? 'Semester', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('GPA: ${gpa.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${(sem['total_credits'] ?? 0).toStringAsFixed(0)} Credits', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
            if (arrears > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$arrears Arrear${arrears > 1 ? 's' : ''}', style: const TextStyle(color: Colors.red, fontSize: 10)),
              ),
            ],
          ],
        ),
        children: [
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(2.5),
                2: FixedColumnWidth(48),
                3: FixedColumnWidth(52),
                4: FixedColumnWidth(56),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  children: [
                    _tableHeader('Code'),
                    _tableHeader('Subject'),
                    _tableHeader('Cr'),
                    _tableHeader('Grade'),
                    _tableHeader('Pts'),
                  ],
                ),
                ...subjects.map((s) {
                  final gc = _gradeColor(s['grade'] ?? '');
                  return TableRow(children: [
                    _tableCell(s['subject_code'] ?? '', color: Colors.white54, size: 11),
                    _tableCell(s['subject_title'] ?? '', size: 11),
                    _tableCell('${s['credits']?.toStringAsFixed(0) ?? '-'}', align: TextAlign.center),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: gc.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(s['grade'] ?? '-', style: TextStyle(color: gc, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    _tableCell('${s['credit_points']?.toStringAsFixed(1) ?? '-'}', align: TextAlign.center),
                  ]);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
    child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _tableCell(String text, {Color? color, double size = 12, TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
    child: Text(text, textAlign: align, overflow: TextOverflow.ellipsis, style: TextStyle(color: color ?? Colors.white70, fontSize: size)),
  );

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 12),
            Text('No university results yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
            SizedBox(height: 8),
            Text('Grades will appear once university exam results are entered', style: TextStyle(color: Colors.white24, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
