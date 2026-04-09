import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ProjectHubScreen extends StatefulWidget {
  final Map<String, dynamic> batch;
  const ProjectHubScreen({super.key, required this.batch});

  @override
  State<ProjectHubScreen> createState() => _ProjectHubScreenState();
}

class _ProjectHubScreenState extends State<ProjectHubScreen> {
  late Map<String, dynamic> _currentBatch;
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentBatch = widget.batch;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ApiService().getCurrentUser();
    setState(() => _currentUser = user);
  }

  Future<void> _refreshBatch() async {
    setState(() => _isLoading = true);
    try {
      final updated = await ApiService().getMyProjectBatch();
      if (updated != null) {
        setState(() => _currentBatch = updated);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Project Hub', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshBatch,
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
                  _buildProjectHeader(),
                  const SizedBox(height: 24),
                  _buildPhaseList(),
                ],
              ),
            ),
    );
  }

  Widget _buildProjectHeader() {
    final title = _currentBatch['project_title'] ?? 'Title Not Set';
    final status = _currentBatch['zeroth_review_status'] ?? 'Pending';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Project Topic', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor(status)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_pin_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Guide: ${_currentBatch['guide_name']}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.greenAccent;
      case 'rejected': return Colors.redAccent;
      default: return Colors.orangeAccent;
    }
  }

  Widget _buildPhaseList() {
    return Column(
      children: [
        _buildPhaseCard(1, 'Team & Guide Allocation', Icons.group_rounded, _buildPhase1Content()),
        _buildPhaseCard(2, 'Base Paper Selection', Icons.article_rounded, _buildPhase2Content()),
        _buildPhaseCard(3, 'Zeroth Review & Approval', Icons.fact_check_rounded, _buildPhase3Content()),
        _buildPhaseCard(4, 'Development Progress', Icons.developer_mode_rounded, _buildPhase4Content()),
        _buildPhaseCard(5, 'Review Cycles (R1, R2, R3)', Icons.auto_graph_rounded, _buildPhase5Content()),
        _buildPhaseCard(6, 'Final Submission', Icons.verified_rounded, _buildPhase6Content()),
      ],
    );
  }

  Widget _buildPhaseCard(int number, String title, IconData icon, Widget content) {
    bool isCompleted = _isPhaseCompleted(number);
    bool isActive = _isPhaseActive(number);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isActive ? Border.all(color: Colors.indigo.shade400, width: 2) : null,
      ),
      child: ExpansionTile(
        initiallyExpanded: isActive,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade50 : (isActive ? Colors.indigo.shade50 : Colors.grey.shade50),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : icon,
            color: isCompleted ? Colors.green : (isActive ? Colors.indigo : Colors.grey),
            size: 20,
          ),
        ),
        title: Text(
          'PHASE $number',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isCompleted ? Colors.green : (isActive ? Colors.indigo : Colors.grey),
          ),
        ),
        subtitle: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: content,
          ),
        ],
      ),
    );
  }

  bool _isPhaseCompleted(int phase) {
    final status = _currentBatch['zeroth_review_status']?.toLowerCase();
    switch (phase) {
      case 1: return true;
      case 2: return _currentBatch['base_papers']?.any((p) => p['is_selected'] == 1) ?? false;
      case 3: return status == 'approved';
      case 4: return _currentBatch['tasks']?.any((t) => t['is_completed'] == 1) ?? false;
      case 5: return _currentBatch['reviews']?.isNotEmpty ?? false;
      default: return false;
    }
  }

  bool _isPhaseActive(int phase) {
    if (phase == 1) return !_isPhaseCompleted(1);
    return _isPhaseCompleted(phase - 1) && !_isPhaseCompleted(phase);
  }

  // PHASE 1: Team
  Widget _buildPhase1Content() {
    final List students = _currentBatch['students'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Team Members', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        ...students.map((s) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: Colors.indigo.shade100, child: Text(s['name'][0])),
          title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(s['reg_no']),
        )),
      ],
    );
  }

  // PHASE 2: Base Papers
  Widget _buildPhase2Content() {
    final List papers = _currentBatch['base_papers'] ?? [];
    final bool isGuide = _currentUser?.role == 'faculty' && _currentBatch['guide_id'] == _currentUser?.userId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Submit 3 Base Papers for evaluation', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 12),
        ...papers.map((p) => Card(
          elevation: 0,
          color: p['is_selected'] == 1 ? Colors.green.shade50 : Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: p['is_selected'] == 1 ? Colors.green : Colors.grey.shade200),
          ),
          child: ListTile(
            title: Text(p['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: p['guide_feedback'] != null ? Text('Guide: ${p['guide_feedback']}') : null,
            trailing: isGuide && p['is_selected'] == 0 
                ? ElevatedButton(
                    onPressed: () => _selectPaper(p['id']),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Select'),
                  )
                : (p['is_selected'] == 1 ? const Icon(Icons.check_circle, color: Colors.green) : null),
          ),
        )),
        if (papers.length < 3 && _currentUser?.role == 'student')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: OutlinedButton.icon(
              onPressed: _showPaperUploadDialog,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Base Paper'),
            ),
          )
      ],
    );
  }

  Future<void> _selectPaper(int paperId) async {
    final feedback = await _showFeedbackDialog('Guide Feedback', 'Enter feedback for this paper selection');
    if (feedback == null) return;
    try {
      await ApiService().selectBasePaper(paperId, feedback: feedback);
      _refreshBatch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // PHASE 3: Approval
  Widget _buildPhase3Content() {
    final status = _currentBatch['zeroth_review_status'] ?? 'Pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentBatch['coordinator_remarks'] != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: Text('Coordinator: ${_currentBatch['coordinator_remarks']}', style: TextStyle(color: Colors.blue.shade900)),
          ),
        const SizedBox(height: 12),
        if (_currentUser?.role == 'student' && status == 'Pending')
          const Text('Wait for Project Coordinator to approve your topic.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        
        // Topic editing for students before approval
        if (_currentUser?.role == 'student' && status != 'Approved')
          ElevatedButton.icon(
            onPressed: _showTopicEditDialog,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Project Topic'),
          ),
      ],
    );
  }

  // PHASE 4: Development
  Widget _buildPhase4Content() {
    final List tasks = _currentBatch['tasks'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${tasks.where((t) => t['is_completed'] == 1).length} / ${tasks.length} Tasks Completed', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: tasks.isEmpty ? 0 : tasks.where((t) => t['is_completed'] == 1).length / tasks.length,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation(Colors.green),
        ),
        const SizedBox(height: 12),
        ...tasks.take(3).map((t) => CheckboxListTile(
          value: t['is_completed'] == 1,
          onChanged: (val) => _updateTaskStatus(t['id'], val! ? 1 : 0),
          title: Text(t['task_name'], style: TextStyle(fontSize: 13, decoration: t['is_completed'] == 1 ? TextDecoration.lineThrough : null)),
        )),
        TextButton(onPressed: () {}, child: const Text('View All Roadmap Tasks')),
      ],
    );
  }

  Future<void> _updateTaskStatus(int taskId, int status) async {
    try {
      await ApiService().updateProjectTask(taskId, status);
      _refreshBatch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // PHASE 5: Reviews
  Widget _buildPhase5Content() {
    final List reviews = _currentBatch['reviews'] ?? [];
    final List ppts = _currentBatch['ppts'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Milestones', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildReviewRow(1, reviews, ppts),
        _buildReviewRow(2, reviews, ppts),
        _buildReviewRow(3, reviews, ppts),
      ],
    );
  }

  Widget _buildReviewRow(int num, List reviews, List ppts) {
    final reviewData = reviews.firstWhere((r) => r['review_number'] == num, orElse: () => null);
    final pptData = ppts.firstWhere((p) => p['review_number'] == num, orElse: () => null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(radius: 12, backgroundColor: reviewData != null ? Colors.green : Colors.grey.shade300, child: Text(num.toString(), style: const TextStyle(fontSize: 10, color: Colors.white))),
          const SizedBox(width: 12),
          Expanded(child: Text('Review $num', style: const TextStyle(fontWeight: FontWeight.w500))),
          if (pptData != null)
            Icon(Icons.slideshow_rounded, color: pptData['guide_approved'] == 1 ? Colors.green : Colors.orange, size: 18),
          const SizedBox(width: 8),
          if (reviewData != null)
            const Text('Evaluated', style: TextStyle(color: Colors.green, fontSize: 12))
          else if (_currentUser?.role == 'student')
            TextButton(onPressed: () => _showPPTUploadDialog(num), child: Text(pptData == null ? 'Upload PPT' : 'Update PPT', style: const TextStyle(fontSize: 12)))
        ],
      ),
    );
  }

  // PHASE 6: Final
  Widget _buildPhase6Content() {
    return Column(
      children: [
        const Text('Upload Final Project Artifacts', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.link_rounded),
          title: const Text('Final Demo Link'),
          trailing: Text(_currentBatch['final_demo_url'] == null ? 'Missing' : 'Uploaded', style: TextStyle(color: _currentBatch['final_demo_url'] == null ? Colors.red : Colors.green)),
          onTap: () => _updateFinalArtifact('final_demo_url'),
        ),
        ListTile(
          leading: const Icon(Icons.description_rounded),
          title: const Text('Final Report (PDF)'),
          trailing: Text(_currentBatch['final_report_url'] == null ? 'Missing' : 'Uploaded', style: TextStyle(color: _currentBatch['final_report_url'] == null ? Colors.red : Colors.green)),
          onTap: () => _updateFinalArtifact('final_report_url'),
        ),
      ],
    );
  }

  // DIALOGS
  void _showPaperUploadDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Base Paper'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Paper Title / Idea', hintText: 'Enter title for base paper')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              await ApiService().submitBasePaper(_currentBatch['id'], ctrl.text, 'N/A');
              if (!context.mounted) return;
              Navigator.pop(context);
              _refreshBatch();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showTopicEditDialog() {
    final ctrl = TextEditingController(text: _currentBatch['project_title']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Project Topic'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Final Project Topic')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ApiService().updateProjectBatch(_currentBatch['id'], {'project_title': ctrl.text});
              if (!context.mounted) return;
              Navigator.pop(context);
              _refreshBatch();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPPTUploadDialog(int reviewNum) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text('Upload PPT for Review $reviewNum'),
      content: const Text('Upload your presentation for guide review.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await ApiService().uploadReviewPPT(_currentBatch['id'], reviewNum, 'PPT_LINK');
          if (!context.mounted) return;
          Navigator.pop(context);
          _refreshBatch();
        }, child: const Text('Submit PPT')),
      ],
    ));
  }

  Future<void> _updateFinalArtifact(String field) async {
    final val = await _showFeedbackDialog('Upload Link', 'Enter URL for project artifact');
    if (val != null) {
      await ApiService().updateProjectBatch(_currentBatch['id'], {field: val});
      _refreshBatch();
    }
  }

  Future<String?> _showFeedbackDialog(String title, String hint) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Submit')),
        ],
      ),
    );
  }
}
