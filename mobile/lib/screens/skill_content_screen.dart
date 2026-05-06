import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'youtube_player_screen.dart';

class SkillContentScreen extends StatefulWidget {
  final LearningResource resource;
  final int initialTab;

  const SkillContentScreen({
    super.key,
    required this.resource,
    this.initialTab = 0,
  });

  @override
  State<SkillContentScreen> createState() => _SkillContentScreenState();
}

class _SkillContentScreenState extends State<SkillContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Learn content ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _sections = [];
  String _summary = '';

  // ── YouTube videos ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _youtubeVideos = [];

  // ── Quiz (from API or static) ──────────────────────────────────────────────
  List<Map<String, dynamic>> _quiz = [];
  List<dynamic> _selectedAnswers = []; // Set<int> for MCS, int? for MCQ
  Map<int, String> _userNatAnswers = {}; // Map of index to string for NAT
  bool _quizSubmitted = false;
  int _score = 0;

  // ── Professional Progression ──────────────────────────────────────────────
  Set<int> _completedSections = {};
  List<String> _roadmap = [];

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _loadingError;
  bool _isMarkingComplete = false;
  bool _isCompleted = false;
  late int _actualResourceId;
  String? _selectedLanguage;        // Programming sub-language (Python, Java…)
  final String _videoLanguage = 'English'; // English only for video content
  String _selectedLevel = 'Beginner'; // Beginner, Intermediate, Advanced
  Map<String, dynamic>? _project;

  // Track completion separately per level (key = level or level/subCategory)
  final Map<String, bool> _levelCompletion = {};

  String get _levelKey => _selectedLanguage != null ? '$_selectedLevel/$_selectedLanguage' : _selectedLevel;

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF6C63FF);
  late Color _skillColor;
  late IconData _skillIcon;

  // ── Glassmorphism / Premium Colors ────────────────────────────────────────
  final Color _glassBackground = Colors.white.withValues(alpha: 0.85);
  final Color _surfaceColor = const Color(0xFFF8F9FF);

  @override
  void initState() {
    super.initState();
    final bool isProgCategory = widget.resource.skillCategory == 'Programming';
    _tabController = TabController(
      length: isProgCategory ? 3 : 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _isCompleted = widget.resource.isCompleted;
    _actualResourceId = widget.resource.resourceId;
    _selectedAnswers = [];
    _userNatAnswers = {};
    _initSkillStyle();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowLanguageSelection();
    });
  }

  Future<void> _checkAndShowLanguageSelection() async {
    if (widget.resource.skillCategory == 'Programming') {
      final lang = await _showLanguageDialog();
      if (lang != null) {
        setState(() => _selectedLanguage = lang);
        _loadContent();
      } else {
        if (mounted) Navigator.pop(context);
      }
    } else {
      _loadContent();
    }
  }

  Future<String?> _showLanguageDialog() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Select Specialization', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLangOption('Python', Icons.terminal),
            _buildLangOption('Java', Icons.coffee),
            _buildLangOption('C++', Icons.terminal),
            _buildLangOption('JavaScript', Icons.javascript),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(String name, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: _skillColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: _skillColor, size: 20),
      ),
      title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () => Navigator.pop(context, name),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initSkillStyle() {
    final cat = widget.resource.skillCategory ?? '';
    switch (cat) {
      case 'Communication':
        _skillColor = const Color(0xFF2196F3);
        _skillIcon = Icons.chat_bubble_rounded;
        break;
      case 'Programming':
        _skillColor = const Color(0xFF4CAF50);
        _skillIcon = Icons.code_rounded;
        break;
      case 'Aptitude':
        _skillColor = const Color(0xFFFF9800);
        _skillIcon = Icons.calculate_rounded;
        break;
      case 'Leadership':
        _skillColor = const Color(0xFF9C27B0);
        _skillIcon = Icons.emoji_events_rounded;
        break;
      default:
        _skillColor = _primary;
        _skillIcon = Icons.star_rounded;
    }
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _loadingError = null;
    });

    final skillCat = widget.resource.skillCategory;
    if (skillCat != null && skillCat.isNotEmpty) {
      await _fetchFromApi();
    } else {
      setState(() {
        _loadingError = 'No category selected';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFromApi() async {
    try {
      final data = await ApiService().getSkillContent(
        widget.resource.skillCategory!,
        language: _videoLanguage,
        subCategory: _selectedLanguage,
        level: _selectedLevel,
      );

      final List<Map<String, dynamic>> sections = List<Map<String, dynamic>>.from(data['sections'] ?? []);
      final List<Map<String, dynamic>> videos = List<Map<String, dynamic>>.from(data['youtube_videos'] ?? []);
      final List<Map<String, dynamic>> quizItems = (data['quiz'] as List?)?.map((q) => _normaliseQuizItem(Map<String, dynamic>.from(q))).toList() ?? [];

      setState(() {
        _summary = data['summary'] as String? ?? '';
        _sections = sections;
        _youtubeVideos = videos;
        _quiz = quizItems;
        _roadmap = List<String>.from(data['roadmap'] ?? []);
        _selectedAnswers = _quiz.map((q) => (q['type'] == 'MCS' ? <int>{} : null)).toList();
        _userNatAnswers = {};
        _completedSections = {};
        _quizSubmitted = false;
        _score = 0;
        _actualResourceId = data['resource_id'] ?? _actualResourceId;
        _project = data['project'] is Map ? Map<String, dynamic>.from(data['project']) : null;
        _isCompleted = _levelCompletion[_levelKey] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadingError = 'Connection failed. Ensure backend is running.';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _normaliseQuizItem(Map<String, dynamic> raw) {
    if (raw.containsKey('type')) return raw;
    final opts = [raw['option_a'] ?? '', raw['option_b'] ?? '', raw['option_c'] ?? '', raw['option_d'] ?? ''];
    final correct = (raw['correct_answer'] as String? ?? 'A').trim().toUpperCase();
    return {
      'question': raw['question'] ?? '',
      'type': 'MCQ',
      'options': opts,
      'correct_answers': [correct.isNotEmpty ? correct[0] : 'A'],
      'explanation': 'Placement focus explanation pending module completion.',
    };
  }

  Future<void> _markComplete() async {
    setState(() => _isMarkingComplete = true);
    try {
      await ApiService().updateResourceProgress(_actualResourceId, true);
      setState(() {
        _isCompleted = true;
        _levelCompletion[_levelKey] = true;
        widget.resource.isCompleted = true;
        for (int i = 0; i < _sections.length; i++) _completedSections.add(i);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Module Mastery Achieved! 🎉', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingComplete = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: _buildAppBar(isDesktop),
      body: _isLoading
          ? _buildLoadingState()
          : _loadingError != null
              ? _buildErrorState()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      children: [
                        _buildHeader(isDesktop),
                        _buildTabBar(isDesktop),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildLearnTab(isDesktop),
                              if (widget.resource.skillCategory == 'Programming')
                                _buildProjectTab(isDesktop),
                              _buildQuizTab(isDesktop),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: (_isLoading || _loadingError != null) ? null : _buildBottomBar(isDesktop),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60, height: 60,
            child: CircularProgressIndicator(color: _skillColor, strokeWidth: 4),
          ),
          const SizedBox(height: 24),
          Text('Generating Elite Content v4.0...', 
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _skillColor)),
          Text('Curating industry case studies', 
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.red.shade300, size: 64),
            const SizedBox(height: 16),
            Text('Sync Interrupted', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_loadingError!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadContent,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Re-Sync'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _skillColor, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: isDesktop,
      title: Column(
        crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(widget.resource.title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          Text('Placement Elite v4.0', style: GoogleFonts.inter(fontSize: 11, color: _skillColor, fontWeight: FontWeight.w600)),
        ],
      ),
      actions: [
        if (_isCompleted)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text('MASTERED', style: GoogleFonts.poppins(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 10, 20, isDesktop ? 40 : 20),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isDesktop ? 80 : 56, height: isDesktop ? 80 : 56,
            decoration: BoxDecoration(color: _skillColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(isDesktop ? 24 : 18)),
            child: Icon(_skillIcon, color: _skillColor, size: isDesktop ? 40 : 30),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_summary.isNotEmpty ? _summary : 'Course overview pending sync...',
                    style: GoogleFonts.inter(fontSize: isDesktop ? 15 : 12.5, color: Colors.grey.shade700, height: 1.5, fontWeight: FontWeight.w500),
                    maxLines: 4, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12, runSpacing: 8,
                  children: [
                    _buildChip('${_sections.length} Labs', Colors.blue),
                    if (_youtubeVideos.isNotEmpty) _buildChip('${_youtubeVideos.length} Masterclasses', Colors.red),
                    _buildChip('Quiz Ready', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTabBar(bool isDesktop) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        labelColor: _skillColor,
        isScrollable: !isDesktop,
        unselectedLabelColor: Colors.grey.shade400,
        indicator: UnderlineTabIndicator(borderSide: BorderSide(color: _skillColor, width: 3), insets: const EdgeInsets.symmetric(horizontal: 20)),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          Tab(text: "KNOWLEDGE"),
          if (widget.resource.skillCategory == 'Programming') Tab(text: "PROJECT"),
          Tab(text: _isCompleted ? "ASSESSMENT" : "LOCKED 🔒"),
        ],
      ),
    );
  }

  Widget _buildLearnTab(bool isDesktop) {
    return ListView(
      padding: EdgeInsets.all(isDesktop ? 40 : 20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildLevelSelector(isDesktop),
        const SizedBox(height: 32),
        _buildSectionLabel('🔥 Advanced Coursework', _skillColor),
        const SizedBox(height: 20),
        ..._sections.asMap().entries.map((entry) => _buildLearningSection(entry.key, entry.value)),
        if (_youtubeVideos.isNotEmpty) ...[
          const SizedBox(height: 40),
          _buildSectionLabel('📺 Industry Masterclasses', Colors.red),
          const SizedBox(height: 20),
          _buildYouTubeContent(isDesktop),
        ],
        if (_completedSections.length == _sections.length && _roadmap.isNotEmpty) ...[
          const SizedBox(height: 48),
          _buildProfessionalRoadmap(isDesktop),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildYouTubeContent(bool isDesktop) {
    if (!isDesktop) {
      return SizedBox(
        height: 190,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _youtubeVideos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) => _buildYouTubeCard(_youtubeVideos[index]),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 220,
      ),
      itemCount: _youtubeVideos.length,
      itemBuilder: (context, index) => _buildYouTubeCard(_youtubeVideos[index]),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: color, letterSpacing: 1.1),
        ),
        const SizedBox(height: 4),
        Container(width: 40, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildYouTubeCard(Map<String, dynamic> video) {
    final title = video['title'] as String? ?? '';
    final thumbnail = video['thumbnail'] as String? ?? '';
    final videoUrl = video['video_url'] as String? ?? '';
    final videoId = video['video_id'] as String? ?? _extractVideoId(videoUrl);

    return GestureDetector(
      onTap: () {
        if (videoId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YoutubePlayerScreen.fromId(videoId: videoId, title: title),
            ),
          );
        }
      },
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (thumbnail.isNotEmpty)
                  Image.network(
                    thumbnail,
                    height: 120, width: 240, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildVideoPlaceholder(),
                  )
                else
                  _buildVideoPlaceholder(),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 0, bottom: 0, left: 0, right: 0,
                  child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3, color: const Color(0xFF2D3436)),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      height: 120, width: 240,
      color: Colors.grey.shade100,
      child: const Icon(Icons.videocam_rounded, color: Colors.grey, size: 30),
    );
  }

  String _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['v'] ?? '';
    } catch (_) {
      return '';
    }
  }

  Widget _buildProfessionalProgressBar() {
    double progress = _sections.isEmpty ? 0 : _completedSections.length / _sections.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Module Progress', 
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              Text('${(progress * 100).toInt()}%', 
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: _skillColor)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _skillColor.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(_skillColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningSection(int index, Map<String, dynamic> section) {
    bool isCompleted = _completedSections.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: isCompleted ? Colors.green.withValues(alpha: 0.2) : Colors.transparent, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: index == 0 && _completedSections.isEmpty,
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade50 : _skillColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted 
                  ? const Icon(Icons.check_rounded, size: 20, color: Colors.green)
                  : Text('${index + 1}', style: GoogleFonts.poppins(color: _skillColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            title: Text(
              section['title']?.toString() ?? 'Core Methodology',
              style: GoogleFonts.poppins(
                fontSize: 14.5, fontWeight: FontWeight.bold, 
                color: isCompleted ? Colors.green.shade800 : const Color(0xFF2D3436)
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F2F6)),
                    const SizedBox(height: 16),
                    if (section['concept_breakdown'] != null) ...[
                      _buildSubSectionHeader(Icons.lightbulb_outline, 'ELITE CONCEPT', Colors.blue),
                      const SizedBox(height: 8),
                      Text(section['concept_breakdown']?.toString() ?? '', 
                        style: GoogleFonts.inter(fontSize: 13.5, color: Colors.grey.shade800, height: 1.6)),
                      const SizedBox(height: 20),
                    ],
                    if (section['industry_context'] != null) ...[
                      _buildSubSectionHeader(Icons.business_center_outlined, 'MNC CASE STUDY', Colors.purple),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF), borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
                        ),
                        child: Text(section['industry_context']?.toString() ?? '',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.purple.shade900, height: 1.5, fontStyle: FontStyle.italic)),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (section['code_lab'] != null) ...[
                      _buildSubSectionHeader(Icons.terminal_rounded, 'PRODUCTION CODE LAB', Colors.green),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(section['code_lab']?.toString() ?? '',
                              style: GoogleFonts.firaCode(fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4)),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.rocket_launch_rounded, size: 14),
                                label: const Text('Simulate Performance'),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                                  foregroundColor: Colors.greenAccent,
                                  textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (section['interview_focus'] != null) ...[
                      _buildSubSectionHeader(Icons.stars_rounded, 'FAANG PREP', Colors.orange),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.tips_and_updates_rounded, color: Colors.orange.shade700, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(section['interview_focus'],
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.orange.shade900, height: 1.5, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildProfessionalRoadmap(bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E), // Deep luxury purple-blue
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E1E2E).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 12 : 10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(isDesktop ? 14 : 12)),
                child: Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: isDesktop ? 28 : 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selection Elite v4.0', 
                      style: GoogleFonts.poppins(color: Colors.amber, fontSize: isDesktop ? 12 : 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    Text('Career Acceleration', 
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: isDesktop ? 22 : 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 24),
          ..._roadmap.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(step, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: isDesktop ? 15 : 13.5, height: 1.4))),
              ],
            ),
          )),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade700]),
              borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('CLAIM SPECIALIZATION BADGE', 
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: isDesktop ? 14 : 13, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector(bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              _buildLevelBtn('Beginner', 'Basic'),
              _buildLevelBtn('Intermediate', 'Elite'),
              _buildLevelBtn('Advanced', 'Mastery'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBtn(String value, String label) {
    bool isSelected = _selectedLevel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedLevel = value;
            _isLoading = true;
          });
          _loadContent();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _skillColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label, 
              style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.bold, 
                color: isSelected ? Colors.white : Colors.grey.shade600
              )),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectTab(bool isDesktop) {
    if (_project == null || _project!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Synthesizing Capstone...', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            Text('Complete more Labs to unlock projects.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.all(isDesktop ? 40 : 20),
      children: [
        _buildSectionLabel('🛠️ Professional Capstone Project', _skillColor),
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_project!['title'] ?? 'Technical Engineering Project',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                       _buildChip(_project!['difficulty'] ?? _selectedLevel, Colors.teal),
                       if (_project!['estimated_duration'] != null) _buildChip(_project!['estimated_duration'], Colors.indigo),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Color(0xFFF1F2F6))),
                  _buildProjectItem(Icons.track_changes_rounded, 'ENGINEERING OBJECTIVE', _project!['objective'] ?? ''),
                  const SizedBox(height: 24),
                  _buildProjectItem(Icons.description_rounded, 'PROJECT OVERVIEW', _project!['description'] ?? ''),
                  const SizedBox(height: 24),
                  if (_project!['tech_stack'] != null) ...[
                    _buildSubSectionHeader(Icons.layers_rounded, 'RECOMMENDED STACK', Colors.blueGrey),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (List<String>.from(_project!['tech_stack'] ?? [])).map((t) => _buildChip(t, Colors.blueGrey)).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_project!['milestones'] != null) ...[
                    _buildSubSectionHeader(Icons.flag_rounded, 'EXECUTION MILESTONES', Colors.deepPurple),
                    const SizedBox(height: 12),
                    ... (List<String>.from(_project!['milestones'] ?? [])).asMap().entries.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.deepPurple.withValues(alpha: 0.1), shape: BoxShape.circle), child: Center(child: Text('${m.key+1}', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepPurple)))),
                          const SizedBox(width: 12),
                          Expanded(child: Text(m.value, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade800))),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _skillColor, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('SUBMIT REPOSITORY LINK', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectItem(IconData icon, String label, String content) {
    if (content.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubSectionHeader(icon, label, Colors.blueGrey),
        const SizedBox(height: 8),
        Text(content, style: GoogleFonts.inter(fontSize: 13.5, color: Colors.grey.shade700, height: 1.5)),
      ],
    );
  }

  Widget _buildQuizTab(bool isDesktop) {
    if (!_isCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.lock_person_rounded, size: 48, color: Colors.amber),
              ),
              const SizedBox(height: 24),
              Text('Assessment Locked', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Complete all knowledge labs to unlock the v4.0 Elite Assessment.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    if (_quiz.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.amber),
            ),
            const SizedBox(height: 24),
            Text('Synthesizing Assessment...', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Our AI is crafting your elite placement quiz.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadContent();
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('RE-SYNTHESIZE NOW'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber.shade800,
                side: BorderSide(color: Colors.amber.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(isDesktop ? 40 : 20),
      children: [
        if (!_quizSubmitted) ...[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: _skillColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: _skillColor.withValues(alpha: 0.1))),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: _skillColor),
                    const SizedBox(width: 16),
                    Expanded(child: Text('Select Elite assessment active. Answer accurately to claim mastery.', style: GoogleFonts.inter(fontSize: 13, color: _skillColor, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                if (_quizSubmitted) _buildQuizResult(),
                ...List.generate(_quiz.length, (i) => _buildQuizQuestion(i)),
                const SizedBox(height: 24),
                if (!_quizSubmitted)
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _submitQuiz,
                      style: ElevatedButton.styleFrom(backgroundColor: _skillColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: Text('FINISH ASSESSMENT', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _resetQuiz,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('RE-ASSESS SKILL'),
                      style: OutlinedButton.styleFrom(foregroundColor: _skillColor, side: BorderSide(color: _skillColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  void _submitQuiz() {
    int score = 0;
    for (int i = 0; i < _quiz.length; i++) {
      final q = _quiz[i];
      final type = q['type'] ?? 'MCQ';
      final corrects = List<String>.from(q['correct_answers'] ?? []);
      bool isCorrect = false;
      if (type == 'MCQ') {
        final selected = _selectedAnswers[i] as int?;
        if (selected != null) {
          final letter = 'ABCD'[selected];
          if (corrects.contains(letter)) isCorrect = true;
        }
      } else if (type == 'MCS') {
        final selectedSet = _selectedAnswers[i] as Set<int>;
        final correctIndices = corrects.map((c) => 'ABCD'.indexOf(c)).toSet();
        if (selectedSet.isNotEmpty && selectedSet.length == correctIndices.length && selectedSet.every((s) => correctIndices.contains(s))) isCorrect = true;
      } else if (type == 'NAT') {
        final userAns = (_userNatAnswers[i] ?? '').trim();
        if (corrects.contains(userAns)) isCorrect = true;
      }
      if (isCorrect) score++;
    }
    setState(() { _quizSubmitted = true; _score = score; });
  }

  void _resetQuiz() {
    setState(() {
      _quizSubmitted = false;
      _score = 0;
      _selectedAnswers = _quiz.map((q) => (q['type'] == 'MCS' ? <int>{} : null)).toList();
      _userNatAnswers = {};
    });
  }

  Widget _buildQuizResult() {
    final percent = (_score / _quiz.length * 100).round();
    final isMastered = percent >= 80;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isMastered ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isMastered ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(isMastered ? Icons.emoji_events_rounded : Icons.psychology_rounded, color: isMastered ? Colors.green : Colors.orange, size: 48),
          const SizedBox(height: 12),
          Text('Score: $_score / ${_quiz.length}', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: isMastered ? Colors.green.shade900 : Colors.orange.shade900)),
          Text(isMastered ? 'PROFICIENCY ACHIEVED' : 'PRACTICE RECOMMENDED', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildQuizQuestion(int index) {
    final q = _quiz[index];
    final type = q['type'] ?? 'MCQ';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUESTION ${index + 1}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: _skillColor, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(q['question'], style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold, height: 1.4, color: const Color(0xFF2D3436))),
          const SizedBox(height: 20),
          if (type == 'MCQ') _buildMCQ(index, q),
          if (type == 'MCS') _buildMCS(index, q),
          if (type == 'NAT') _buildNAT(index, q),
          if (_quizSubmitted) ...[
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Text('Expl: ${q['explanation'] ?? 'Elite breakdown.'}', style: GoogleFonts.inter(fontSize: 12.5, color: Colors.blue.shade900))),
          ],
        ],
      ),
    );
  }

  Widget _buildMCQ(int qIndex, Map<String, dynamic> q) {
    final options = List<String>.from(q['options']);
    return Column(children: options.asMap().entries.map((e) => _buildOption(qIndex, e.key, e.value, false)).toList());
  }

  Widget _buildMCS(int qIndex, Map<String, dynamic> q) {
    final options = List<String>.from(q['options']);
    return Column(children: options.asMap().entries.map((e) => _buildOption(qIndex, e.key, e.value, true)).toList());
  }

  Widget _buildNAT(int qIndex, Map<String, dynamic> q) {
    return TextField(
      onChanged: (v) => setState(() => _userNatAnswers[qIndex] = v),
      decoration: InputDecoration(hintText: 'Enter value', filled: true, fillColor: const Color(0xFFF8F9FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }

  Widget _buildOption(int qIndex, int optIndex, String text, bool isMulti) {
    bool isSelected = isMulti ? (_selectedAnswers[qIndex] as Set<int>).contains(optIndex) : _selectedAnswers[qIndex] == optIndex;
    return GestureDetector(
      onTap: () {
        if (_quizSubmitted) return;
        setState(() {
          if (isMulti) {
            isSelected ? (_selectedAnswers[qIndex] as Set<int>).remove(optIndex) : (_selectedAnswers[qIndex] as Set<int>).add(optIndex);
          } else {
            _selectedAnswers[qIndex] = optIndex;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isSelected ? _skillColor.withValues(alpha: 0.05) : const Color(0xFFF8F9FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected ? _skillColor : Colors.transparent, width: 1.5)),
        child: Row(
          children: [
            Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? _skillColor : Colors.grey.shade300, width: 2), color: isSelected ? _skillColor : Colors.transparent), child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? _skillColor : Colors.grey.shade800))),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, isDesktop ? 20 : 32),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
      child: Row(
        mainAxisAlignment: isDesktop ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (isDesktop) const Spacer(),
          Expanded(
            flex: isDesktop ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text('ELITE MODULE', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500)), 
                Text('Version 4.0 Stable', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))
              ]
            )
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isCompleted ? null : _markComplete,
            style: ElevatedButton.styleFrom(backgroundColor: _isCompleted ? Colors.green : _skillColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text(_isCompleted ? 'MASTERED ✓' : 'MARK COMPLETE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
          ),
          if (isDesktop) const Spacer(),
        ],
      ),
    );
  }
}
