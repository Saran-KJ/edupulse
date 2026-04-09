import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';

class AddReviewDialog extends StatefulWidget {
  final Map<String, dynamic> batch;
  final VoidCallback onReviewAdded;

  const AddReviewDialog({super.key, required this.batch, required this.onReviewAdded});

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  int _selectedReview = 1;
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _feedbackControllers = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final List students = widget.batch['students'] ?? [];
    for (var s in students) {
      _marksControllers[s['reg_no']] = TextEditingController();
      _feedbackControllers[s['reg_no']] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _marksControllers.values) {
      c.dispose();
    }
    for (var c in _feedbackControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _submitting = true);
    try {
      final List students = widget.batch['students'] ?? [];
      final List<Map<String, dynamic>> marksList = [];

      for (var s in students) {
        final regNo = s['reg_no'];
        final marks = double.tryParse(_marksControllers[regNo]!.text) ?? 0.0;
        marksList.add({
          'student_reg_no': regNo,
          'marks': marks,
          'feedback': _feedbackControllers[regNo]!.text,
        });
      }

      await ApiService().recordProjectReview({
        'batch_id': widget.batch['id'],
        'review_number': _selectedReview,
        'student_marks': marksList,
      });

      widget.onReviewAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List students = widget.batch['students'] ?? [];

    return AlertDialog(
      title: Text('Add Review for Batch #${widget.batch['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _selectedReview,
              decoration: const InputDecoration(labelText: 'Review Phase', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0. Zeroth Review (Ideation)')),
                DropdownMenuItem(value: 1, child: Text('1. Review 1 (Planning)')),
                DropdownMenuItem(value: 2, child: Text('2. Review 2 (Mid-term)')),
                DropdownMenuItem(value: 3, child: Text('3. Review 3 (Pre-Final)')),
              ],
              onChanged: (val) => setState(() => _selectedReview = val!),
            ),
            const SizedBox(height: 20),
            const Text('Enter Marks & Feedback per Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const Divider(),
            ...students.map((s) {
              final regNo = s['reg_no'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s['name']} ($regNo)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _marksControllers[regNo],
                            decoration: const InputDecoration(labelText: 'Marks (100)', border: OutlineInputBorder(), isDense: true),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _feedbackControllers[regNo],
                            decoration: const InputDecoration(labelText: 'Feedback', border: OutlineInputBorder(), isDense: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Batch Marks'),
        ),
      ],
    );
  }
}

class ProjectApprovalDialog extends StatefulWidget {
  final Map<String, dynamic> batch;
  final VoidCallback onUpdated;

  const ProjectApprovalDialog({super.key, required this.batch, required this.onUpdated});

  @override
  State<ProjectApprovalDialog> createState() => _ProjectApprovalDialogState();
}

class _ProjectApprovalDialogState extends State<ProjectApprovalDialog> {
  final _remarksController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _remarksController.text = widget.batch['coordinator_remarks'] ?? '';
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _submitting = true);
    try {
      await ApiService().updateProjectBatch(widget.batch['id'], {
        'zeroth_review_status': status,
        'coordinator_remarks': _remarksController.text,
      });
      widget.onUpdated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Project Approval (Zeroth Review)', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Topic: ${widget.batch['project_title'] ?? "Not Set"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 16),
          TextField(
            controller: _remarksController,
            decoration: const InputDecoration(labelText: 'Coordinator Remarks', border: OutlineInputBorder()),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submitting ? null : () => _updateStatus('Rejected'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : () => _updateStatus('Approved'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}
