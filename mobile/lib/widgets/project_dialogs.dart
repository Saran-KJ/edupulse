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
  final _marksController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _submitting = false;

  Future<void> _submitReview() async {
    final marks = double.tryParse(_marksController.text);
    if (marks == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid marks')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService().recordProjectReview(
        batchId: widget.batch['id'],
        reviewNumber: _selectedReview,
        marks: marks,
        feedback: _feedbackController.text,
      );
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
    return AlertDialog(
      title: Text('Add Review for Batch #${widget.batch['id']}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedReview,
              decoration: const InputDecoration(labelText: 'Review Number', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Review 1 (Planning)')),
                DropdownMenuItem(value: 2, child: Text('Review 2 (Core Implementation)')),
                DropdownMenuItem(value: 3, child: Text('Review 3 (Final/Model)')),
              ],
              onChanged: (val) => setState(() => _selectedReview = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _marksController,
              decoration: const InputDecoration(labelText: 'Marks (out of 100)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(labelText: 'Faculty Feedback', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Submit'),
        ),
      ],
    );
  }
}
