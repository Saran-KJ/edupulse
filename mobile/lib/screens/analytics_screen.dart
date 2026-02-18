import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate Reports',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildReportButton(
              'Download Class Report (PDF)',
              Icons.picture_as_pdf,
              Colors.red,
              () => _downloadReport(),
            ),
            const SizedBox(height: 16),
            _buildReportButton(
              'Export Attendance (Excel)',
              Icons.table_chart,
              Colors.green,
              () => _exportAttendance(),
            ),
            const SizedBox(height: 16),
            _buildReportButton(
              'Export Marks (Excel)',
              Icons.assessment,
              Colors.orange,
              () => _exportMarks(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          alignment: Alignment.centerLeft,
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
