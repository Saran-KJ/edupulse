import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AdvisorStudentLearningScreen extends StatefulWidget {
  final String dept;
  final int year;
  final String section;

  const AdvisorStudentLearningScreen({
    super.key,
    required this.dept,
    required this.year,
    required this.section,
  });

  @override
  State<AdvisorStudentLearningScreen> createState() => _AdvisorStudentLearningScreenState();
}

class _AdvisorStudentLearningScreenState extends State<AdvisorStudentLearningScreen> {
  final ApiService _apiService = ApiService();
  List<StudentLearningStatusItem> _students = [];
  List<HighRiskAlert> _alerts = [];
  bool _isLoading = true;
  String? _error;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final progressData = await _apiService.getAdvisorStudentProgress(
        widget.dept, widget.year, widget.section,
      );
      final alertsData = await _apiService.getHighRiskAlerts(
        dept: widget.dept, year: widget.year, section: widget.section,
      );

      setState(() {
        _students = (progressData['students'] as List? ?? [])
            .map((s) => StudentLearningStatusItem.fromJson(s))
            .toList();
        _alerts = (alertsData['alerts'] as List? ?? [])
            .map((a) => HighRiskAlert.fromJson(a))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learning Progress - ${widget.dept} Year ${widget.year} ${widget.section}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_alerts.isNotEmpty) _buildAlertBanner(),
                        const SizedBox(height: 12),
                        _buildSummaryCards(),
                        const SizedBox(height: 16),
                        _buildStudentList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildAlertBanner() {
    return Card(
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
                const SizedBox(width: 8),
                Text('⚠ ${_alerts.length} High-Risk Alert(s)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700], fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            ..._alerts.map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alert.alertSeverity == 'critical' ? Colors.red[100] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: alert.alertSeverity == 'critical' ? Colors.red : Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(alert.alertSeverity.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${alert.studentName} (${alert.regNo})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('High-risk subjects: ${alert.highRiskSubjects.join(", ")}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    const SizedBox(height: 4),
                    ...alert.recommendedActions.map((action) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_right, size: 16, color: Colors.red[400]),
                          Expanded(child: Text(action, style: const TextStyle(fontSize: 11))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final highCount = _students.where((s) => s.overallRisk == 'High').length;
    final medCount = _students.where((s) => s.overallRisk == 'Medium').length;
    final lowCount = _students.where((s) => s.overallRisk == 'Low').length;

    return Row(
      children: [
        _buildSummaryChip('High Risk', highCount, Colors.red),
        const SizedBox(width: 8),
        _buildSummaryChip('Medium Risk', medCount, Colors.orange),
        const SizedBox(width: 8),
        _buildSummaryChip('Low Risk', lowCount, Colors.green),
      ],
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Students (${_students.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_students.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No students found with learning plans')),
            ),
          )
        else
          ...List.generate(_students.length, (index) {
            final student = _students[index];
            final isExpanded = _expandedIndex == index;
            final riskColor = _getRiskColor(student.overallRisk);

            return Card(
              elevation: isExpanded ? 4 : 1,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: riskColor.withOpacity(0.15),
                            child: Icon(
                              student.overallRisk == 'High' ? Icons.warning :
                              student.overallRisk == 'Medium' ? Icons.info : Icons.check,
                              color: riskColor, size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.studentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(student.regNo,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                          // Risk badges
                          if (student.highRiskCount > 0)
                            _buildMiniRiskBadge('H', student.highRiskCount, Colors.red),
                          if (student.mediumRiskCount > 0)
                            _buildMiniRiskBadge('M', student.mediumRiskCount, Colors.orange),
                          if (student.lowRiskCount > 0)
                            _buildMiniRiskBadge('L', student.lowRiskCount, Colors.green),
                          const SizedBox(width: 4),
                          Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.grey[400]),
                        ],
                      ),
                      // Progress bar
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: student.overallProgress / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${student.overallProgress.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      // Expanded subject details
                      if (isExpanded) ...[
                        const Divider(height: 20),
                        ...student.subjects.map((sub) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: _getRiskColor(sub.riskLevel),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(sub.subjectTitle,
                                  style: const TextStyle(fontSize: 13)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getRiskColor(sub.riskLevel).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(sub.riskLevel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getRiskColor(sub.riskLevel),
                                  )),
                              ),
                              const SizedBox(width: 8),
                              Text(sub.focusType,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMiniRiskBadge(String letter, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$letter:$count',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
