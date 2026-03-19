import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'youtube_player_screen.dart';

class SkillContentScreen extends StatefulWidget {
  final LearningResource resource;
  final int initialTab;

  const SkillContentScreen({
    Key? key,
    required this.resource,
    this.initialTab = 0,
  }) : super(key: key);

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
  Map<int, int?> _sectionQuizAnswers = {}; // Mapping of section index to selected option A(0), B(1)...
  Map<int, bool?> _sectionQuizCorrect = {}; // Mapping of section index to correctness
  List<String> _roadmap = [];
  bool _showRoadmap = false;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _loadingError;
  bool _isMarkingComplete = false;
  bool _isCompleted = false;
  late int _actualResourceId;
  String? _selectedLanguage;        // Programming sub-language (Python, Java…)
  String _videoLanguage = 'English'; // Tamil or English for video content
  String _selectedLevel = 'Beginner'; // Beginner, Intermediate, Advanced
  Map<String, dynamic>? _project;

  // Track completion separately per level (key = level or level/subCategory)
  final Map<String, bool> _levelCompletion = {};

  String get _levelKey => _selectedLanguage != null ? '$_selectedLevel/$_selectedLanguage' : _selectedLevel;

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF6C63FF);
  late Color _skillColor;
  late IconData _skillIcon;

  @override
  void initState() {
    super.initState();
    final bool _isProgCategory = widget.resource.skillCategory == 'Programming';
    _tabController = TabController(
      length: _isProgCategory ? 3 : 2,
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
        // If they cancel, go back
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Programming Language', style: TextStyle(fontWeight: FontWeight.bold)),
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
      leading: Icon(icon, color: _skillColor),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        _skillIcon = Icons.chat_bubble_outline;
        break;
      case 'Programming':
        _skillColor = const Color(0xFF4CAF50);
        _skillIcon = Icons.code;
        break;
      case 'Aptitude':
        _skillColor = const Color(0xFFFF9800);
        _skillIcon = Icons.calculate_outlined;
        break;
      case 'Critical Thinking':
        _skillColor = const Color(0xFFE91E63);
        _skillIcon = Icons.lightbulb_outline;
        break;
      case 'Leadership':
        _skillColor = const Color(0xFF9C27B0);
        _skillIcon = Icons.groups_outlined;
        break;
      default:
        _skillColor = _primary;
        _skillIcon = Icons.star_outline;
    }
  }

  /// Load content — prefer calling API for skill categories to get Gemini+YouTube enriched content.
  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _loadingError = null;
    });

    final skillCat = widget.resource.skillCategory;
    final hasSkillCat = skillCat != null && skillCat.isNotEmpty;

    if (hasSkillCat) {
      // Always fetch from API for skills to get Gemini + YouTube + AI Quiz
      await _fetchFromApi();
    } else {
      // Academic internal resource
      final raw = widget.resource.content;
      final hasStaticContent = raw != null && raw.isNotEmpty;

      if (hasStaticContent) {
        try {
          final decoded = jsonDecode(raw);
          final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
          setState(() {
            _sections = List<Map<String, dynamic>>.from(data['sections'] ?? []);
            _quiz = List<Map<String, dynamic>>.from(data['quiz'] ?? []);
            
            // Initialise answers based on type
            _selectedAnswers = _quiz.map((q) {
              final type = q['type'] ?? 'MCQ';
              if (type == 'MCS') return <int>{};
              return null; // MCQ
            }).toList();
            _userNatAnswers = {};

            _summary = data['summary'] as String? ?? '';
            _isLoading = false;
          });
        } catch (_) {
          setState(() {
            _loadingError = 'Invalid content format';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _loadingError = 'No content available for this resource';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFromApi() async {
    try {
      final skillCat = widget.resource.skillCategory ?? '';
      final data = await ApiService().getSkillContent(
        skillCat,
        language: _videoLanguage,
        subCategory: _selectedLanguage,
        level: _selectedLevel,
      );

      // Sections from Gemini
      final rawSections = data['sections'];
      final List<Map<String, dynamic>> sections = rawSections is List
          ? rawSections.map((s) => Map<String, dynamic>.from(s as Map)).toList()
          : [];

      // YouTube videos
      final rawVideos = data['youtube_videos'];
      final List<Map<String, dynamic>> videos = rawVideos is List
          ? rawVideos.map((v) => Map<String, dynamic>.from(v as Map)).toList()
          : [];

      // Quiz from Gemini (raw list with option_a/b/c/d format)
      final rawQuiz = data['quiz'];
      final List<Map<String, dynamic>> quizItems = rawQuiz is List
          ? rawQuiz.map((q) => _normaliseQuizItem(Map<String, dynamic>.from(q as Map))).toList()
          : [];

      setState(() {
        _summary = data['summary'] as String? ?? '';
        _sections = sections;
        _youtubeVideos = videos;
        _quiz = quizItems;
        _roadmap = List<String>.from(data['roadmap'] ?? []);
        _selectedAnswers = _quiz.map((q) {
          final type = q['type'] ?? 'MCQ';
          if (type == 'MCS') return <int>{};
          return null; // MCQ
        }).toList();
        _userNatAnswers = {};
        _completedSections = {};
        _sectionQuizAnswers = {};
        _sectionQuizCorrect = {};
        _quizSubmitted = false;
        _score = 0;

        // Adopt the real resource ID from the server
        _actualResourceId = data['resource_id'] ?? _actualResourceId;
        _project = data['project'] is Map ? Map<String, dynamic>.from(data['project']) : null;

        // Restore completion status for this specific level
        _isCompleted = _levelCompletion[_levelKey] ?? false;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadingError = 'Failed to load content. $e';
        _isLoading = false;
      });
    }
  }

  /// Normalise quiz items that use option_a/b/c/d + correct_answer (A/B/C/D)
  /// into the {question, options, answer} format used by the quiz widget.
  Map<String, dynamic> _normaliseQuizItem(Map<String, dynamic> raw) {
    // If it has "type", it's the new rich format, use as is
    if (raw.containsKey('type')) {
      return raw;
    }
    // Fallback for old/academic static format
    if (raw.containsKey('options') && raw.containsKey('answer')) {
      return {
        ...raw,
        'type': 'MCQ',
        'correct_answers': [raw['answer'].toString()],
        'explanation': 'No explanation available.',
      };
    }
    // API format (old) → static format
    final opts = [
      raw['option_a'] ?? '',
      raw['option_b'] ?? '',
      raw['option_c'] ?? '',
      raw['option_d'] ?? '',
    ];
    final correctLetterRaw = (raw['correct_answer'] as String? ?? 'A').trim().toUpperCase();
    final correctLetter = correctLetterRaw.isNotEmpty ? correctLetterRaw[0] : 'A';
    
    return {
      'question': raw['question'] ?? '',
      'type': 'MCQ',
      'options': opts,
      'correct_answers': [correctLetter],
      'explanation': 'No explanation available.',
    };
  }

  // ── Complete ────────────────────────────────────────────────────────────────
  Future<void> _markComplete() async {
    setState(() => _isMarkingComplete = true);
    try {
      await ApiService().updateResourceProgress(_actualResourceId, true);
      setState(() {
        _isCompleted = true;
        _levelCompletion[_levelKey] = true; // Save per-level completion
        widget.resource.isCompleted = true;
        // Mark all sections as complete at once
        for (int i = 0; i < _sections.length; i++) {
          _completedSections.add(i);
        }
        _showRoadmap = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Module Completed! Great work! 🎉'),
            ]),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingComplete = false);
    }
  }

  // ── Quiz submit / reset ─────────────────────────────────────────────────────
  void _submitQuiz() {
    int score = 0;
    
    int letterToIndex(String letter) {
      letter = letter.trim().toUpperCase();
      if (letter.isEmpty) return -1;
      return 'ABCD'.indexOf(letter[0]);
    }

    for (int i = 0; i < _quiz.length; i++) {
      final q = _quiz[i];
      final type = q['type'] ?? 'MCQ';
      final corrects = List<String>.from(q['correct_answers'] ?? []);
      
      bool isCorrect = false;

      if (type == 'MCQ') {
        final selected = _selectedAnswers[i] as int?;
        if (selected != null) {
          // Check if selected index matches any correct answer (as letter or index string)
          for (var c in corrects) {
            if (selected == letterToIndex(c) || selected.toString() == c) {
              isCorrect = true;
              break;
            }
          }
        }
      } else if (type == 'MCS') {
        final selectedSet = _selectedAnswers[i] as Set<int>;
        final correctIndices = corrects.map((c) => letterToIndex(c)).where((idx) => idx != -1).toSet();
        
        // Also check if they provided indices as strings
        for (var c in corrects) {
          final idx = int.tryParse(c);
          if (idx != null) correctIndices.add(idx);
        }

        if (selectedSet.isNotEmpty && 
            selectedSet.length == correctIndices.length && 
            selectedSet.every((s) => correctIndices.contains(s))) {
          isCorrect = true;
        }
      } else if (type == 'NAT') {
        final userAns = (_userNatAnswers[i] ?? '').trim().toLowerCase();
        final correctAns = (corrects.isNotEmpty ? corrects[0] : '').trim().toLowerCase();
        // Basic string match for numbers, handles "25" vs "25.0" if they are identical strings
        if (userAns.isNotEmpty && userAns == correctAns) {
          isCorrect = true;
        } else if (double.tryParse(userAns) != null && double.tryParse(correctAns) != null) {
          // Numeric match
          if (double.parse(userAns) == double.parse(correctAns)) {
            isCorrect = true;
          }
        }
      }

      if (isCorrect) score++;
    }

    setState(() {
      _quizSubmitted = true;
      _score = score;
    });
  }

  void _resetQuiz() {
    setState(() {
      _quizSubmitted = false;
      _score = 0;
      _selectedAnswers = _quiz.map((q) {
        final type = q['type'] ?? 'MCQ';
        if (type == 'MCS') return <int>{};
        return null;
      }).toList();
      _userNatAnswers = {};
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _loadingError != null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLearnTab(),
                          if (widget.resource.skillCategory == 'Programming')
                            _buildProjectTab(),
                          _buildQuizTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: (_isLoading || _loadingError != null) ? null : _buildBottomBar(),
    );
  }

  // ── Loading State ───────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _skillColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CircularProgressIndicator(color: _skillColor, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Generating AI content...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _skillColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching videos & quiz from Llama 3.2:1b (Local AI) + YouTube',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 60),
            const SizedBox(height: 16),
            Text(_loadingError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadContent,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _skillColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black87,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.resource.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            widget.resource.skillCategory ?? 'Skill Development',
            style: TextStyle(fontSize: 12, color: _skillColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      actions: [
        if (_isCompleted)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text('Done',
                    style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _skillColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_skillIcon, color: _skillColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_summary.isNotEmpty)
                  Text(
                    _summary,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (widget.resource.description != null)
                  Text(
                    widget.resource.description!,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildChip('${_sections.length} Sections', Colors.blue),
                    if (_youtubeVideos.isNotEmpty)
                      _buildChip('${_youtubeVideos.length} Videos', Colors.red),
                    _buildChip('${_quiz.length} Quiz Q\'s', Colors.purple),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  // ── Tab Bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _skillColor,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorColor: _skillColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.menu_book_outlined, size: 16),
                SizedBox(width: 6),
                Text('Learn'),
              ],
            ),
          ),
          if (widget.resource.skillCategory == 'Programming')
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.assignment_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Project'),
                ],
              ),
            ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isCompleted ? Icons.quiz_outlined : Icons.lock_outline, size: 16),
                const SizedBox(width: 6),
                Text(_isCompleted
                    ? (_quizSubmitted ? 'Quiz ($_score/${_quiz.length})' : 'Quiz')
                    : 'Quiz 🔒'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LEARN TAB ──────────────────────────────────────────────────────────────
  Widget _buildLearnTab() {
    if (_sections.isEmpty && _youtubeVideos.isEmpty) {
      return const Center(child: Text('No content available.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLevelSelector(),
        const SizedBox(height: 10),
        _buildVideoLanguageToggle(),
        const SizedBox(height: 10),
        _buildProfessionalProgressBar(),
        const SizedBox(height: 20),

        // YouTube Videos Section
        if (_youtubeVideos.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📺 Recommended Videos',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _videoLanguage == 'Tamil'
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _videoLanguage == 'Tamil'
                        ? Colors.orange.shade300
                        : Colors.blue.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _videoLanguage == 'Tamil' ? '🇮🇳' : '🇬🇧',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _videoLanguage,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _videoLanguage == 'Tamil'
                            ? Colors.orange.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _youtubeVideos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildYouTubeCard(_youtubeVideos[index]),
            ),
          ),
          const SizedBox(height: 30),
        ]
        else if (!_isLoading) ...[
          // No videos placeholder
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.play_circle_outline, color: Colors.grey.shade400, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No videos found for $_videoLanguage',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Try switching to English for more video options.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        _buildSectionLabel('📖 Professional Learning Content', _skillColor),
        const SizedBox(height: 15),

        ..._sections.asMap().entries.map((entry) {
          return _buildLearningSection(entry.key, entry.value);
        }).toList(),

        if (_completedSections.length == _sections.length && _roadmap.isNotEmpty)
          _buildProfessionalRoadmap(),

        const SizedBox(height: 100),
      ],
    );
  }

  /// Tamil / English toggle for video content.
  Widget _buildVideoLanguageToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangToggleBtn('English', '🇬🇧'),
          const SizedBox(width: 4),
          _buildLangToggleBtn('Tamil', '🇮🇳'),
        ],
      ),
    );
  }

  Widget _buildLangToggleBtn(String lang, String flag) {
    final selected = _videoLanguage == lang;
    return GestureDetector(
      onTap: () {
        if (!selected) {
          setState(() {
            _videoLanguage = lang;
            _youtubeVideos = []; // Clear old videos while reloading
          });
          _fetchFromApi();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              lang,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildYouTubeCard(Map<String, dynamic> video) {
    final title = video['title'] as String? ?? '';
    final thumbnail = video['thumbnail'] as String? ?? '';
    final videoUrl = video['video_url'] as String? ?? '';
    final videoId = video['video_id'] as String? ?? _extractVideoId(videoUrl);
    final lang = video['language'] as String? ?? _videoLanguage;
    final isTamil = lang == 'Tamil';

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
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button + language badge
            Stack(
              children: [
                if (thumbnail.isNotEmpty)
                  Image.network(
                    thumbnail,
                    height: 118,
                    width: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 118,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.play_circle_outline, color: Colors.grey.shade400, size: 40),
                    ),
                  )
                else
                  Container(
                    height: 118,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.play_circle_outline, color: Colors.grey.shade400, size: 40),
                  ),
                // Language badge (top-left)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isTamil ? Colors.orange.shade700 : Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isTamil ? '🇮🇳 Tamil' : '🇬🇧 English',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Play button (bottom-right)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Text(
                title,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _skillColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _skillColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Professional Progress',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _skillColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _skillColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_skillColor),
              minHeight: 8,
            ),
          ),
          if (!_isCompleted)
             Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Text(
                 'Read all sections and mark as complete to unlock the quiz & roadmap',
                 style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == 0 && _completedSections.isEmpty,
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.shade50 : _skillColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted 
                ? const Icon(Icons.check, size: 18, color: Colors.green)
                : Text('${index + 1}', style: TextStyle(color: _skillColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          title: Text(
            section['title'] ?? 'Section ${index + 1}',
            style: TextStyle(
              fontSize: 15, 
              fontWeight: FontWeight.bold, 
              color: isCompleted ? Colors.green.shade800 : Colors.black87
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    section['body'] ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProfessionalRoadmap() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_skillColor, _skillColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _skillColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'Professional Roadmap',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock your elite potential with these targeted next steps.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ..._roadmap.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.double_arrow_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4))),
              ],
            ),
          )).toList(),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Module Certification Unlocked 🎓',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── QUIZ TAB ─────────────────────────────────────────────────────────────────
  Widget _buildQuizTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── LOCKED STATE: quiz not yet unlocked ──────────────────────────────────
    if (!_isCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade200, width: 2),
                ),
                child: Icon(Icons.lock_outline, size: 44, color: Colors.amber.shade700),
              ),
              const SizedBox(height: 24),
              Text(
                'Quiz Locked',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 12),
              Text(
                'Complete the $_selectedLevel learning content first, then tap "Mark Complete" to unlock your quiz.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Go to Learn Tab'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _skillColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_quiz.isEmpty) {
      return const Center(child: Text('No quiz available for this skill.'));
    }

    // Defensive check: ensure answers list matches quiz length
    if (_selectedAnswers.length < _quiz.length) {
       return const Center(child: Text('Preparing quiz...'));
    }

    bool allAnswered = true;
    for (int i = 0; i < _quiz.length; i++) {
      final type = _quiz[i]['type'] ?? 'MCQ';
      if (type == 'MCQ' && _selectedAnswers[i] == null) allAnswered = false;
      if (type == 'MCS' && (_selectedAnswers[i] as Set).isEmpty) allAnswered = false;
      if (type == 'NAT' && (_userNatAnswers[i] ?? '').isEmpty) allAnswered = false;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_quizSubmitted) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_skillColor.withOpacity(0.08), _skillColor.withOpacity(0.02)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _skillColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _skillColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Answer all ${_quiz.length} questions (Mix of MCQ, Multiple Correct, and Numerical) then tap Submit.',
                    style: TextStyle(color: _skillColor, fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_quizSubmitted) _buildQuizResult(),
        ...List.generate(_quiz.length, (i) => _buildQuizQuestion(i)),
        const SizedBox(height: 16),
        if (!_quizSubmitted)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: allAnswered ? _submitQuiz : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _skillColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                allAnswered ? 'Submit Answers' : 'Answer all questions to submit',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        if (_quizSubmitted)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _resetQuiz,
              icon: const Icon(Icons.refresh),
              label: const Text('Retake Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _skillColor,
                side: BorderSide(color: _skillColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildQuizResult() {
    final percent = (_score / _quiz.length * 100).round();
    Color resultColor;
    String resultMessage;
    IconData resultIcon;

    if (percent >= 80) {
      resultColor = Colors.green.shade700;
      resultMessage = 'Excellent! You have mastered this skill! 🎉';
      resultIcon = Icons.emoji_events;
    } else if (percent >= 60) {
      resultColor = Colors.orange.shade700;
      resultMessage = 'Good effort! Review the sections above and try again.';
      resultIcon = Icons.thumb_up_outlined;
    } else {
      resultColor = Colors.red.shade700;
      resultMessage = 'Keep practising! Read through the Learn tab again.';
      resultIcon = Icons.school_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: resultColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: resultColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(resultIcon, color: resultColor, size: 40),
          const SizedBox(height: 10),
          Text(
            'Your Score: $_score / ${_quiz.length}  ($percent%)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: resultColor),
          ),
          const SizedBox(height: 8),
          Text(
            resultMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: resultColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizQuestion(int index) {
    final q = _quiz[index];
    final type = q['type'] ?? 'MCQ';
    final question = q['question'] as String;
    final explanation = q['explanation'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: _skillColor.withOpacity(0.12), shape: BoxShape.circle),
                  child: Center(
                    child: Text('${index + 1}',
                        style: TextStyle(color: _skillColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(question,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
                      const SizedBox(height: 4),
                      Text(
                        type == 'MCS' ? ' (Multiple solutions correct)' : (type == 'NAT' ? ' (Numeric answer)' : ''),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (type == 'MCQ') _buildMCQ(index, q),
            if (type == 'MCS') _buildMCS(index, q),
            if (type == 'NAT') _buildNAT(index, q),
            if (_quizSubmitted && explanation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Explanation:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Text(explanation, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMCQ(int qIndex, Map<String, dynamic> q) {
    final options = List<String>.from(q['options'] as List);
    final corrects = List<String>.from(q['correct_answers'] ?? []);
    
    int letterToIndex(String letter) {
      letter = letter.trim().toUpperCase();
      if (letter.isEmpty) return -1;
      return 'ABCD'.indexOf(letter[0]);
    }

    return Column(
      children: options.asMap().entries.map((entry) {
        final optIndex = entry.key;
        final text = entry.value;
        final selected = _selectedAnswers[qIndex];
        final isSelected = selected == optIndex;
        
        bool isCorrect = false;
        for (var c in corrects) {
          if (optIndex == letterToIndex(c) || optIndex.toString() == c) {
            isCorrect = true;
            break;
          }
        }

        return _buildOptionWidget(
          qIndex: qIndex,
          optIndex: optIndex,
          text: text,
          isSelected: isSelected,
          isCorrect: isCorrect,
          isMultiple: false,
          onTap: () {
            if (!_quizSubmitted) {
              setState(() => _selectedAnswers[qIndex] = optIndex);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildMCS(int qIndex, Map<String, dynamic> q) {
    final options = List<String>.from(q['options'] as List);
    final corrects = List<String>.from(q['correct_answers'] ?? []);
    
    int letterToIndex(String letter) {
      letter = letter.trim().toUpperCase();
      if (letter.isEmpty) return -1;
      return 'ABCD'.indexOf(letter[0]);
    }

    return Column(
      children: options.asMap().entries.map((entry) {
        final optIndex = entry.key;
        final text = entry.value;
        final selectedSet = _selectedAnswers[qIndex] as Set<int>;
        final isSelected = selectedSet.contains(optIndex);
        
        bool isCorrect = false;
        for (var c in corrects) {
          if (optIndex == letterToIndex(c) || optIndex.toString() == c) {
            isCorrect = true;
            break;
          }
        }

        return _buildOptionWidget(
          qIndex: qIndex,
          optIndex: optIndex,
          text: text,
          isSelected: isSelected,
          isCorrect: isCorrect,
          isMultiple: true,
          onTap: () {
            if (!_quizSubmitted) {
              setState(() {
                if (isSelected) {
                  selectedSet.remove(optIndex);
                } else {
                  selectedSet.add(optIndex);
                }
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildNAT(int qIndex, Map<String, dynamic> q) {
    final corrects = List<String>.from(q['correct_answers'] ?? []);
    final correctAns = corrects.isNotEmpty ? corrects[0] : '';
    final userAns = _userNatAnswers[qIndex] ?? '';
    
    bool isCorrect = false;
    if (_quizSubmitted) {
      if (userAns.trim().toLowerCase() == correctAns.trim().toLowerCase()) {
        isCorrect = true;
      } else if (double.tryParse(userAns) != null && double.tryParse(correctAns) != null) {
        if (double.parse(userAns) == double.parse(correctAns)) isCorrect = true;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_quizSubmitted)
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter numerical answer',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (val) => setState(() => _userNatAnswers[qIndex] = val),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isCorrect ? Colors.green.shade200 : Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Answer: $userAns',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: isCorrect ? Colors.green.shade800 : Colors.red.shade800)),
                if (!isCorrect) ...[
                  const SizedBox(height: 4),
                  Text('Correct Answer: $correctAns',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOptionWidget({
    required int qIndex,
    required int optIndex,
    required String text,
    required bool isSelected,
    required bool isCorrect,
    required bool isMultiple,
    required VoidCallback onTap,
  }) {
    Color borderColor;
    Color bgColor;
    Color textColor = Colors.black87;
    Widget? trailingIcon;

    if (_quizSubmitted) {
      if (isCorrect) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        textColor = Colors.green.shade900;
        trailingIcon = Icon(Icons.check_circle, color: Colors.green.shade600, size: 18);
      } else if (isSelected) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor = Colors.red.shade900;
        trailingIcon = Icon(Icons.cancel, color: Colors.red.shade600, size: 18);
      } else {
        bgColor = Colors.white;
        borderColor = Colors.grey.shade200;
      }
    } else {
      bgColor = isSelected ? _skillColor.withOpacity(0.08) : Colors.white;
      borderColor = isSelected ? _skillColor : Colors.grey.shade200;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected || (isCorrect && _quizSubmitted) ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: isMultiple ? BorderRadius.circular(4) : BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
                color: isSelected && !_quizSubmitted ? _skillColor : Colors.transparent,
              ),
              child: isSelected && !_quizSubmitted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 13.5, color: textColor, fontWeight: FontWeight.bold)),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Beginner', label: Text('Basic'), icon: Icon(Icons.star_border, size: 16)),
          ButtonSegment(value: 'Intermediate', label: Text('Medium'), icon: Icon(Icons.star_half, size: 16)),
          ButtonSegment(value: 'Advanced', label: Text('Expert'), icon: Icon(Icons.star, size: 16)),
        ],
        selected: {_selectedLevel},
        onSelectionChanged: (newVal) {
          setState(() {
            _selectedLevel = newVal.first;
            _isLoading = true;
          });
          _loadContent();
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: _skillColor,
          selectedForegroundColor: Colors.white,
          side: BorderSide(color: _skillColor.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildProjectTab() {
    if (_project == null || _project!.isEmpty) {
      return const Center(child: Text('Complete more sessions to unlock projects!'));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionLabel('🛠️ Professional Capstone Project', Colors.teal),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _project!['title'] ?? 'Technical Project',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _project!['difficulty'] ?? _selectedLevel,
                  style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 30),
              if ((_project!['objective'] ?? '').toString().trim().isNotEmpty) ...[
                _buildProjectItem('Objective', _project!['objective'] ?? ''),
                const SizedBox(height: 20),
              ],
              if ((_project!['description'] ?? '').toString().trim().isNotEmpty) ...[
                _buildProjectItem('Description', _project!['description'] ?? ''),
                const SizedBox(height: 20),
              ],
              if ((_project!['tech_stack'] is List) && (_project!['tech_stack'] as List).isNotEmpty) ...[
                const Text('Suggested Tech Stack:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: (List<String>.from(_project!['tech_stack'])).map((tech) => Chip(
                    label: Text(tech, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide.none,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectItem(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
        const SizedBox(height: 6),
        Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
      ],
    );
  }

  // ── Bottom Bar ──────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_sections.length} sections',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  Text('${_quiz.length} quiz questions',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _isCompleted
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                        const SizedBox(width: 6),
                        Text('Completed',
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _isMarkingComplete ? null : _markComplete,
                    icon: _isMarkingComplete
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(_isMarkingComplete ? 'Saving...' : 'Mark Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _skillColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
