import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ActivityApprovalScreen extends StatefulWidget {
  final String dept;
  final int year;
  final String section;

  const ActivityApprovalScreen({
    super.key,
    required this.dept,
    required this.year,
    required this.section,
  });

  @override
  State<ActivityApprovalScreen> createState() => _ActivityApprovalScreenState();
}

class _ActivityApprovalScreenState extends State<ActivityApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StudentActivitySubmission> _pendingSubmissions = [];
  List<StudentActivitySubmission> _reviewedSubmissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSubmissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final pending = await ApiService().getPendingSubmissions(
        widget.dept, widget.year, widget.section, status: 'pending',
      );
      final approved = await ApiService().getPendingSubmissions(
        widget.dept, widget.year, widget.section, status: 'approved',
      );
      final rejected = await ApiService().getPendingSubmissions(
        widget.dept, widget.year, widget.section, status: 'rejected',
      );
      setState(() {
        _pendingSubmissions = pending;
        _reviewedSubmissions = [...approved, ...rejected];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reviewSubmission(int id, String status, {String? comment}) async {
    try {
      await ApiService().reviewSubmission(id, status, comment: comment);
      _loadSubmissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission ${status == "approved" ? "approved" : "rejected"} successfully!'),
            backgroundColor: status == "approved" ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReviewDialog(StudentActivitySubmission submission, String action) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                action == 'approved' ? Icons.check_circle : Icons.cancel,
                color: action == 'approved' ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text('${action == "approved" ? "Approve" : "Reject"} Submission'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                submission.activityName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'By: ${submission.regNo}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Comment (optional)',
                  hintText: 'Add a review comment...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'approved' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _reviewSubmission(
                  submission.id,
                  action,
                  comment: commentController.text.isNotEmpty ? commentController.text : null,
                );
              },
              child: Text(action == 'approved' ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type) {
      case 'Sports':
        return Icons.sports;
      case 'Hackathon':
        return Icons.code;
      case 'Workshop':
        return Icons.build;
      case 'Symposium':
        return Icons.groups;
      case 'Seminar':
        return Icons.school;
      case 'Competition':
        return Icons.emoji_events;
      default:
        return Icons.local_activity;
    }
  }

  Widget _buildSubmissionCard(StudentActivitySubmission sub, {bool showActions = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getActivityTypeIcon(sub.activityType),
                    color: Colors.purple.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.activityName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sub.activityType} • ${sub.level ?? ""}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (!showActions)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(sub.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sub.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(sub.status),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Student info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.blue.shade800),
                  const SizedBox(width: 6),
                  Text(
                    'Reg No: ${sub.regNo}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(sub.activityDate, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                if (sub.role != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.badge, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(sub.role!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
                if (sub.achievement != null && sub.achievement!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.emoji_events, size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(sub.achievement!, style: TextStyle(fontSize: 13, color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
            if (sub.description != null && sub.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                sub.description!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (sub.reviewComment != null && sub.reviewComment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.comment, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Comment: ${sub.reviewComment}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showReviewDialog(sub, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showReviewDialog(sub, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Co/Extra-curricular Approvals - ${widget.dept} Yr ${widget.year} ${widget.section}'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_pendingSubmissions.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingSubmissions.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Approved'),
            const Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSubmissions,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pending tab
                  _pendingSubmissions.isEmpty
                      ? _buildEmptyState('No pending submissions')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pendingSubmissions.length,
                          itemBuilder: (context, index) =>
                              _buildSubmissionCard(_pendingSubmissions[index], showActions: true),
                        ),
                  // Approved tab
                  _reviewedSubmissions.where((s) => s.status == 'approved').isEmpty
                      ? _buildEmptyState('No approved submissions')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reviewedSubmissions.where((s) => s.status == 'approved').length,
                          itemBuilder: (context, index) {
                            final approved = _reviewedSubmissions.where((s) => s.status == 'approved').toList();
                            return _buildSubmissionCard(approved[index]);
                          },
                        ),
                  // Rejected tab
                  _reviewedSubmissions.where((s) => s.status == 'rejected').isEmpty
                      ? _buildEmptyState('No rejected submissions')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reviewedSubmissions.where((s) => s.status == 'rejected').length,
                          itemBuilder: (context, index) {
                            final rejected = _reviewedSubmissions.where((s) => s.status == 'rejected').toList();
                            return _buildSubmissionCard(rejected[index]);
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
