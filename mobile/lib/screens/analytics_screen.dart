import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  DashboardStats? _stats;
  HodReportSummary? _reportSummary;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getDashboardStats(),
        _apiService.getHODReportSummary(),
      ]);
      setState(() {
        _stats = results[0] as DashboardStats;
        _reportSummary = results[1] as HodReportSummary;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Reports'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildSubjectRiskSection(),
                  const SizedBox(height: 24),
                  _buildCriticalStudentsSection(),
                  const SizedBox(height: 32),
                  const Text(
                    'Export & Downloads',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildReportButton(
                    'Consolidated Internal Report (PDF)',
                    Icons.picture_as_pdf,
                    Colors.red,
                    () => _downloadReport(),
                  ),
                  const SizedBox(height: 12),
                  _buildReportButton(
                    'Attendance Deficiency (Excel)',
                    Icons.table_chart,
                    Colors.green,
                    () => _exportAttendance(),
                  ),
                  const SizedBox(height: 12),
                  _buildReportButton(
                    'Detailed Mark Sheet (Excel)',
                    Icons.assessment,
                    Colors.orange,
                    () => _exportMarks(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    if (_stats == null) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _buildStatCard('Total Students', _stats!.totalStudents.toString(), Icons.people, Colors.blue),
        _buildStatCard('Avg Attendance', '${_stats!.avgAttendance}%', Icons.event_available, Colors.teal),
        _buildStatCard('High Performers', _stats!.highPerformers.toString(), Icons.emoji_events, Colors.amber),
        _buildStatCard('At-Risk Students', _stats!.atRiskCount.toString(), Icons.warning_amber_rounded, Colors.deepOrange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildSubjectRiskSection() {
    if (_reportSummary == null || _reportSummary!.atRiskBySubject.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject Performance Risks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reportSummary!.atRiskBySubject.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final subject = _reportSummary!.atRiskBySubject[index];
              return ListTile(
                title: Text(subject.subjectTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(subject.subjectCode, style: const TextStyle(fontSize: 12)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${subject.highRiskCount} High Risk', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${subject.mediumRiskCount} Med Risk', style: const TextStyle(color: Colors.orange, fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalStudentsSection() {
    if (_reportSummary == null || _reportSummary!.criticalStudents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Students Requiring Intervention',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._reportSummary!.criticalStudents.take(3).map((student) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Text(student.regNo.substring(student.regNo.length - 2), style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
                title: Text(student.regNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Score: ${student.riskScore}%'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ),
            )),
      ],
    );
  }

  Widget _buildReportButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadReport() async {
    try {
      await _apiService.downloadClassReport();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading report: $e')),
        );
      }
    }
  }

  Future<void> _exportAttendance() async {
    try {
      await _apiService.exportAttendance();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting attendance: $e')),
        );
      }
    }
  }

  Future<void> _exportMarks() async {
    try {
      await _apiService.exportClassMarks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting marks: $e')),
        );
      }
    }
  }
}
