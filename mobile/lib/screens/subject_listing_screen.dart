import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SubjectListingScreen extends StatefulWidget {
  const SubjectListingScreen({super.key});

  @override
  State<SubjectListingScreen> createState() => _SubjectListingScreenState();
}

class _SubjectListingScreenState extends State<SubjectListingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'PEC', 'OEC'
  ];

  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadSubjects();
      }
    });
    _loadSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final semester = _tabs[_tabController.index];
      final subjects = await ApiService().getSubjects(semester: semester);
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subjects: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSubjects {
    if (_searchQuery.isEmpty) return _subjects;
    final q = _searchQuery.toLowerCase();
    return _subjects.where((s) {
      return (s['subject_code'] ?? '').toString().toLowerCase().contains(q) ||
          (s['subject_title'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'CORE':
        return const Color(0xFF2563EB);
      case 'LAB':
        return const Color(0xFF059669);
      case 'PEC':
        return const Color(0xFF7C3AED);
      case 'OEC':
        return const Color(0xFFD97706);
      case 'EEC':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'CORE':
        return Icons.menu_book_rounded;
      case 'LAB':
        return Icons.science_rounded;
      case 'PEC':
        return Icons.extension_rounded;
      case 'OEC':
        return Icons.public_rounded;
      case 'EEC':
        return Icons.work_rounded;
      default:
        return Icons.subject_rounded;
    }
  }

  double _totalCredits() {
    double total = 0;
    for (final s in _filteredSubjects) {
      total += (s['credits'] ?? 0).toDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Subjects Catalog'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search bar + stats
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by code or title...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Semester ${_tabs[_tabController.index]}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    Row(
                      children: [
                        _statChip(
                          Icons.book_outlined,
                          '${_filteredSubjects.length} Subjects',
                          const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        _statChip(
                          Icons.stars_rounded,
                          '${_totalCredits()} Credits',
                          const Color(0xFF059669),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Subject list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSubjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No subjects match your search'
                                  : 'No subjects for this semester',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSubjects.length,
                        itemBuilder: (context, index) =>
                            _buildSubjectCard(_filteredSubjects[index], index),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, int index) {
    final code = subject['subject_code'] ?? '';
    final title = subject['subject_title'] ?? '';
    final category = subject['category'] ?? '';
    final credits = (subject['credits'] ?? 0).toDouble();
    final color = _categoryColor(category);
    final icon = _categoryIcon(category);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Credits
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${credits % 1 == 0 ? credits.toInt() : credits}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const Text(
                      'Credits',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
