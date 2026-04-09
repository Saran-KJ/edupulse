import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/project_dialogs.dart';
import '../config/app_theme.dart';

class ProjectCoordinatorManagementScreen extends StatefulWidget {
  final String dept;
  final int assignedYear;

  const ProjectCoordinatorManagementScreen({
    super.key, 
    required this.dept, 
    required this.assignedYear
  });

  @override
  State<ProjectCoordinatorManagementScreen> createState() => _ProjectCoordinatorManagementScreenState();
}

class _ProjectCoordinatorManagementScreenState extends State<ProjectCoordinatorManagementScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _faculty = [];
  String? _selectedSection; // null means All

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadBatches();
    await _loadFaculty();
  }

  Future<void> _loadFaculty() async {
    try {
      final faculty = await ApiService().getDepartmentFaculty(widget.dept);
      setState(() {
        _faculty = faculty.map((f) => {'user_id': f.userId, 'name': f.name}).toList();
      });
    } catch (e) {
      debugPrint('Error loading faculty: $e');
    }
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    try {
      final batches = await ApiService().getCoordinatorBatches(
        section: _selectedSection,
      );
      // Filter by the year and dept this screen is for (in case of multiple roles)
      final filteredBatches = batches.where((b) => 
        b['dept'] == widget.dept && b['year'] == widget.assignedYear
      ).toList();
      setState(() => _batches = filteredBatches);
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('403')) {
          msg = "Access Denied: You are not authorized to view these batches.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSectionChanged(String? section) {
    setState(() => _selectedSection = section);
    _loadBatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Projects - Year ${widget.assignedYear}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _batches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No batches found for Section ${_selectedSection ?? "All"} in Year ${widget.assignedYear}',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _batches.length,
                        itemBuilder: (ctx, index) {
                          final batch = _batches[index];
                          final students = batch['students'] as List<dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Batch #${batch['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                                      Chip(
                                        avatar: const Icon(Icons.person, size: 16),
                                        label: Text(batch['guide_name'] ?? 'Unknown Guide'),
                                        backgroundColor: Colors.blue.shade50,
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  const Text('Students:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  ...students.map((s) => Text('${s['reg_no']} - ${s['name']}')),
                                  const SizedBox(height: 12),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Project Topic:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                              Text(batch['project_title'] ?? 'Not Set', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(batch['zeroth_review_status'] ?? 'Pending').withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: _getStatusColor(batch['zeroth_review_status'] ?? 'Pending')),
                                          ),
                                          child: Text(
                                            (batch['zeroth_review_status'] ?? 'Pending').toUpperCase(),
                                            style: TextStyle(color: _getStatusColor(batch['zeroth_review_status'] ?? 'Pending'), fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Reviewer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                            Text(batch['reviewer_name'] ?? 'Not Assigned', style: TextStyle(color: batch['reviewer_name'] == null ? Colors.orange : Colors.black)),
                                          ],
                                        ),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () => _openAssignReviewerDialog(batch),
                                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                                            label: const Text('Assign Reviewer'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                            ElevatedButton.icon(
                                              onPressed: () => _openApprovalDialog(batch),
                                              icon: const Icon(Icons.verified_user_rounded, size: 18),
                                              label: const Text('Zeroth Review'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () => _openAddReviewDialog(batch),
                                              icon: const Icon(Icons.rate_review, size: 18),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.primary,
                                                side: const BorderSide(color: AppColors.primary),
                                              ),
                                              label: const Text('Add Review'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter by Section:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          SegmentedButton<String?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All'), icon: Icon(Icons.all_inclusive, size: 16)),
              ButtonSegment(value: 'A', label: Text('Sec A')),
              ButtonSegment(value: 'B', label: Text('Sec B')),
              ButtonSegment(value: 'C', label: Text('Sec C')),
            ],
            selected: {_selectedSection},
            onSelectionChanged: (val) => _onSectionChanged(val.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _openAssignReviewerDialog(Map<String, dynamic> batch) {
    int? selectedReviewerId = batch['reviewer_id'];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Reviewer - Batch #${batch['id']}'),
          content: DropdownButtonFormField<int>(
            initialValue: selectedReviewerId,
            decoration: const InputDecoration(labelText: 'Select Faculty', border: OutlineInputBorder()),
            items: _faculty.map((f) => DropdownMenuItem(value: f['user_id'] as int, child: Text(f['name']))).toList(),
            onChanged: (val) => setDialogState(() => selectedReviewerId = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedReviewerId == null ? null : () async {
                try {
                  await ApiService().assignBatchReviewer(batch['id'], selectedReviewerId!);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadBatches();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddReviewDialog(Map<String, dynamic> batch) {
    showDialog(
      context: context,
      builder: (ctx) => AddReviewDialog(
        batch: batch,
        onReviewAdded: _loadBatches,
      ),
    );
  }

  void _openApprovalDialog(Map<String, dynamic> batch) {
    showDialog(
      context: context,
      builder: (ctx) => ProjectApprovalDialog(
        batch: batch,
        onUpdated: _loadBatches,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }
}
