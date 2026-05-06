import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'skill_content_screen.dart';
import '../widgets/responsive_layout.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;
  String? _selectedSkill;

  final List<Map<String, dynamic>> _skills = [
    {
      "code": "SKILL_PROG",
      "title": "Programming Mastery",
      "icon": Icons.code_rounded,
      "description": "Elite coding, system design, and algorithms.",
      "color": const Color(0xFF4CAF50),
      "gradient": [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      "category": "Programming"
    },
    {
      "code": "SKILL_APT",
      "title": "Aptitude Elite",
      "icon": Icons.analytics_rounded,
      "description": "Quant, logic, and rapid problem solving.",
      "color": const Color(0xFFFF9800),
      "gradient": [Color(0xFFFF9800), Color(0xFFE65100)],
      "category": "Aptitude"
    },
    {
      "code": "SKILL_COMM",
      "title": "Global Comm",
      "icon": Icons.record_voice_over_rounded,
      "description": "Corporate communication and persuasion.",
      "color": const Color(0xFF2196F3),
      "gradient": [Color(0xFF2196F3), Color(0xFF0D47A1)],
      "category": "Communication"
    },
    {
      "code": "SKILL_SOFT",
      "title": "Leadership Ace",
      "icon": Icons.auto_graph_rounded,
      "description": "Strategy, management, and team lead.",
      "color": const Color(0xFF9C27B0),
      "gradient": [Color(0xFF9C27B0), Color(0xFF4A148C)],
      "category": "Leadership"
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) setState(() => _isLoading = true);
    try {
      final data = await ApiService().getOverallLearningView();
      if (mounted) {
        setState(() {
          _data = data;
          _selectedSkill = data['learning_sub_preference'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6C63FF)),
              const SizedBox(height: 20),
              Text('Entering Skill Hub...', 
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text("Connectivity Issue", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, style: GoogleFonts.inter(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _fetchData, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final contentPadding = isDesktop ? screenWidth * 0.1 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(isDesktop),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(contentPadding, 24, contentPadding, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(isDesktop),
                      const SizedBox(height: 32),
                      _buildSectionHeader("Skill Explorer", "Select your specialization"),
                      const SizedBox(height: 20),
                      _buildSkillGrid(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDesktop) {
    return SliverAppBar(
      expandedHeight: isDesktop ? 220 : 180,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF6C63FF),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text("Skill Hub", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: false,
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6C63FF), 
                    Color(0xFF8B5CF6),
                    Color(0xFF3F37C9)
                  ],
                ),
              ),
            ),
            // Decorative Mesh Elements
            Positioned(
              right: -30, top: -20,
              child: Opacity(
                opacity: 0.2,
                child: Container(
                  width: 250, height: 250,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
            Positioned(
              left: -50, bottom: -50,
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  width: 200, height: 200,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
            Positioned(
              left: isDesktop ? 100 : 20,
              bottom: 45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("WELCOME BACK, SCHOLAR", 
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 12),
                  Text("PLACEMENT ELITE v4.0", 
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: isDesktop ? 32 : 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Text("Track your engineering mastery and interview readiness", 
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: isDesktop ? 14 : 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDesktop) {
    final progress = _data?['total_progress'] ?? 0.0;
    
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildMainMasteryCard(progress, true)),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _buildStatMiniCard("Daily Streak", "🚀 12 Days", "Keep the momentum!")),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _buildStatMiniCard("Skill Medals", "🏅 04 Earned", "Top 5% of class")),
        ],
      );
    }

    return Column(
      children: [
        _buildMainMasteryCard(progress, false),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatMiniCard("Streak", "🚀 12", "Keep going")),
            const SizedBox(width: 12),
            Expanded(child: _buildStatMiniCard("Medals", "🏅 04", "Pro Level")),
          ],
        ),
      ],
    );
  }

  Widget _buildMainMasteryCard(double progress, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 28 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: isDesktop ? 80 : 64,
                height: isDesktop ? 80 : 64,
                child: CircularProgressIndicator(
                  value: progress / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                ),
              ),
              Text("${progress.toInt()}%", 
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: isDesktop ? 18 : 14)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("OVERALL MASTERY", 
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.0)),
                Text("Level: Elite Candidate", 
                  style: GoogleFonts.poppins(fontSize: isDesktop ? 20 : 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
                const SizedBox(height: 4),
                Text("Next Goal: System Arch Specialist", 
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), 
            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Text(value, 
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
          const SizedBox(height: 2),
          Text(subtitle, 
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildSkillGrid(BuildContext context) {
    final crossAxisCount = ResponsiveBreakpoints.getCrossAxisCount(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: crossAxisCount >= 4 ? 0.88 : 0.82,
      ),
      itemCount: _skills.length,
      itemBuilder: (context, index) {
        final skill = _skills[index];
        final isSelected = _selectedSkill == skill['category']; // Match by category
        
        return _buildSkillCard(skill, isSelected);
      },
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill, bool isSelected) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(isHovered ? 1.03 : 1.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isHovered ? skill['color'] : Colors.transparent, 
                width: 2
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovered 
                    ? skill['color'].withValues(alpha: 0.15) 
                    : Colors.black.withValues(alpha: 0.04), 
                  blurRadius: isHovered ? 25 : 15, 
                  offset: const Offset(0, 8)
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => _openSkillModule(skill['category']),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: skill['gradient']),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: skill['color'].withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Icon(skill['icon'], color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    Text(skill['title'], 
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, height: 1.2)),
                    const SizedBox(height: 8),
                    // Mini Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isSelected ? 0.45 : 0.0, // Mock individual progress
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(skill['color']),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isSelected ? "CONTINUE" : "START", 
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: skill['color'], letterSpacing: 0.5)),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: skill['color']),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  void _openSkillModule(String category) {
    // Map category to a stable, large ID
    final Map<String, int> stableIds = {
      'Aptitude': 900001,
      'Programming': 900002,
      'Communication': 900003,
      'Leadership': 900004,
      'Critical Thinking': 900005,
    };
    final stableId = stableIds[category] ?? 900000;

    final resource = LearningResource(
      resourceId: stableId,
      title: "$category Development",
      description: "AI-powered $category learning and quiz module.",
      url: "ai_skill://$category",
      type: "course",
      tags: "skill,$category",
      isCompleted: false,
      skillCategory: category,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillContentScreen(
          resource: resource,
        ),
      ),
    ).then((_) => _fetchData());
  }
}
