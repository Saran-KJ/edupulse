import 'package:flutter/material.dart';
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
      "code": "SKILL_APT",
      "title": "Aptitude Training",
      "icon": Icons.calculate,
      "description": "Logical reasoning and numerical ability."
    },
    {
      "code": "SKILL_PROG",
      "title": "Programming Essentials",
      "icon": Icons.code,
      "description": "Data structures and algorithm basics."
    },
    {
      "code": "SKILL_COMM",
      "title": "Business Communication",
      "icon": Icons.forum,
      "description": "Professional speaking and writing skills."
    },
    {
      "code": "SKILL_SOFT",
      "title": "Soft Skills",
      "icon": Icons.psychology,
      "description": "Personality development and leadership."
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getOverallLearningView();
      setState(() {
        _data = data;
        _selectedSkill = data['learning_sub_preference'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectSkill(String skillCode) async {
    setState(() => _isLoading = true);
    try {
      await ApiService().submitGlobalPathPreference("Skill Development", subChoice: skillCode);
      await _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

    final path = _data?['learning_path_preference'] ?? "Skill Development";

    return Scaffold(
      appBar: AppBar(
        title: Text(path == "Skill Development" ? "Skill Hub" : "Academic Hub"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ContentConstraints(
          maxWidth: 1200,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(path),
              const SizedBox(height: 24),
              _buildSkillView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String path) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            path == "Skill Development" ? Icons.psychology : Icons.school,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path == "Skill Development" ? "Master Your Skills" : "Academic Success",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  path == "Skill Development" ? "Choose a skill to pursue" : "AI-powered study strategy ready",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillView() {
    final Map<String, String> categoryMap = {
      'SKILL_APT': 'Aptitude',
      'SKILL_PROG': 'Programming',
      'SKILL_COMM': 'Communication',
      'SKILL_SOFT': 'Leadership',
    };

    final crossAxisCount = ResponsiveBreakpoints.getCrossAxisCount(
      context,
      mobile: 2,
      tablet: 2,
      desktop: 4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Choose Your Path", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: ResponsiveBreakpoints.isDesktop(context) ? 1.1 : 1.0,
          ),
          itemCount: _skills.length,
          itemBuilder: (context, index) {
            final skill = _skills[index];
            final isSelected = _selectedSkill == skill['code'];
            final backendCategory = categoryMap[skill['code']] ?? 'Aptitude';
            
            return HoverScaleEffect(
              onTap: () async {
                setState(() => _selectedSkill = skill['code']);
                _openSkillModule(backendCategory);
                try {
                  await ApiService().submitGlobalPathPreference("Skill Development", subChoice: skill['code']);
                } catch (_) {}
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade200, 
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (isSelected ? Colors.blue : Colors.grey).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        skill['icon'], 
                        color: isSelected ? Colors.blue : Colors.grey.shade700, 
                        size: ResponsiveBreakpoints.isDesktop(context) ? 48 : 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      skill['title'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveBreakpoints.isDesktop(context) ? 18 : 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue.shade900 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      skill['description'],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: ResponsiveBreakpoints.isDesktop(context) ? 12 : 11, 
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContentPlaceholder(String title, String category, String type) {
    return Card(
      child: ListTile(
        leading: Icon(type == 'video' ? Icons.play_circle_outline : Icons.description),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openSkillModule(category),
      ),
    );
  }

  void _openSkillModule(String category, {int initialTab = 0}) {
    // Map category to a stable, large ID to avoid collisions and overflows
    final Map<String, int> stableIds = {
      'Aptitude': 900001,
      'Programming': 900002,
      'Communication': 900003,
      'Leadership': 900004,
      'Critical Thinking': 900005,
    };
    final stableId = stableIds[category] ?? 900000;

    // Create a resource object — the backend will now return the real persistent ID
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
          initialTab: initialTab,
        ),
      ),
    ).then((_) => _fetchData());
  }


}
