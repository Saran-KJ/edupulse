import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'quiz_screen.dart';
import 'skill_content_screen.dart';
import 'youtube_player_screen.dart';

class LearningResourcesScreen extends StatefulWidget {
  final String subjectCode;
  final String subjectTitle;
  final String? riskLevel;

  const LearningResourcesScreen({
    Key? key,
    required this.subjectCode,
    required this.subjectTitle,
    this.riskLevel,
  }) : super(key: key);

  @override
  _LearningResourcesScreenState createState() => _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  bool _isLoading = true;
  List<LearningResource> _resources = [];
  Map<String, dynamic>? _planData;
  String? _error;
  String _selectedLanguage = "English";
  int? _playingResourceId;
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    _loadPlanAndResources();
  }

  Future<void> _loadPlanAndResources() async {
    setState(() => _isLoading = true);
    try {
      final data = widget.riskLevel == null
          ? await ApiService().getAllSubjectResources(
              widget.subjectCode,
              language: _selectedLanguage,
            )
          : await ApiService().getAllSubjectResources(
              widget.subjectCode,
              language: _selectedLanguage,
              riskLevel: widget.riskLevel,
            );
      final list = data['resources'] is List ? data['resources'] as List<dynamic> : [];
      setState(() {
        _resources = list.map((json) => LearningResource.fromJson(json)).toList();
        _planData = data['plan'] is Map<String, dynamic> ? data['plan'] : null;
        _error = null;
      });

      // If LOW risk and pending choice, show dialog
      if (_planData != null && _planData!['pending_choice'] == true) {
        _showChoiceDialog();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _playResource(LearningResource resource) {
    if (_playingResourceId == resource.resourceId) {
      setState(() {
        _playingResourceId = null;
        _ytController?.close();
        _ytController = null;
      });
      return;
    }

    final videoId = YoutubePlayerController.convertUrlToId(resource.url);
    if (videoId != null) {
      setState(() {
        _playingResourceId = resource.resourceId;
        _ytController?.close();
        _ytController = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            mute: false,
          ),
        );
      });
    } else {
      _launchUrl(resource.url);
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  Future<void> _showChoiceDialog() async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events, color: Colors.green.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("Great Performance!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your risk level is LOW for this subject. Proceed with Skill Development:",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildChoiceOption(
              icon: Icons.psychology,
              color: Colors.purple,
              title: "Skill Development",
              subtitle: "Build professional skills (Communication, Programming, etc.)",
              onTap: () => Navigator.pop(ctx, "skill_development"),
            ),
          ],
        ),
      ),
    );

    if (choice != null && mounted) {
      try {
        await ApiService().submitLowRiskChoice(widget.subjectCode, choice);
        // No skill selection dialog — student can access ALL skills freely
        _loadPlanAndResources();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showSkillSelectionDialog(List<String> skills) async {
    final skillIcons = {
      'Communication': Icons.chat_bubble_outline,
      'Programming': Icons.code,
      'Aptitude': Icons.calculate,
      'Critical Thinking': Icons.lightbulb_outline,
      'Leadership': Icons.groups_outlined,
    };

    final skill = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Select a Skill", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose a skill area to develop:",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ...skills.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.purple.shade100),
                ),
                leading: Icon(skillIcons[s] ?? Icons.star, color: Colors.purple.shade700),
                title: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pop(ctx, s),
              ),
            )),
          ],
        ),
      ),
    );

    if (skill != null && mounted) {
      try {
        await ApiService().submitSkillSelection(widget.subjectCode, skill);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildChoiceOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch: $url')),
        );
      }
    }
  }

  Future<void> _toggleResourceCompletion(LearningResource resource) async {
    try {
      final newStatus = !resource.isCompleted;
      await ApiService().updateResourceProgress(resource.resourceId, newStatus);
      setState(() => resource.isCompleted = newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(widget.subjectTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _loadPlanAndResources,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFilterSection(),
                              const SizedBox(height: 16),
                              if (_planData != null) _buildPlanHeader(),
                              const SizedBox(height: 16),
                              if (_planData != null && _planData!['practice_schedule'] != null)
                                _buildPracticeScheduleSection(),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isSkillDevelopmentPlan ? "Skill Development" : "Assigned Resources",
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                  ),
                                  if (_error == null && !_isLoading && _resources.isNotEmpty) _buildOverallProgress(),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      if (_resources.isEmpty)
                        SliverToBoxAdapter(child: _buildEmptyState())
                      else if (_isSkillDevelopmentPlan)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final items = _buildSkillGroupedItems();
                              final item = items[index];
                              if (item is String) {
                                return _buildSkillCategoryHeader(item);
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                                child: _buildResourceCard(item as LearningResource),
                              );
                            },
                            childCount: _buildSkillGroupedItems().length,
                          ),
                        )
                      else
                        Builder(builder: (context) {
                          final items = _buildTypeGroupedItems();
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = items[index];
                                if (item is String) {
                                  return _buildTypeCategoryHeader(item);
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                                  child: _buildResourceCard(item as LearningResource),
                                );
                              },
                              childCount: items.length,
                            ),
                          );
                        }),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                    ],
                  ),
                ),
    );
  }

  // Whether current plan is a Skill Development plan
  bool get _isSkillDevelopmentPlan =>
      _planData != null && _planData!['focus_type'] == 'Skill Development';

  // Build a flat list of String (category headers) and LearningResource (cards)
  // for grouped rendering in Skill Development mode
  List<dynamic> _buildSkillGroupedItems() {
    final Map<String, List<LearningResource>> grouped = {};
    const order = ['Communication', 'Programming', 'Aptitude', 'Critical Thinking', 'Leadership'];
    for (final r in _resources) {
      final cat = r.skillCategory ?? 'Other';
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add(r);
    }
    final result = <dynamic>[];
    for (final cat in order) {
      if (grouped.containsKey(cat)) {
        result.add(cat); // header
        result.addAll(grouped[cat]!);
      }
    }
    return result;
  }

  Widget _buildSkillCategoryHeader(String category) {
    final Map<String, IconData> icons = {
      'Communication': Icons.chat_bubble_outline,
      'Programming': Icons.code,
      'Aptitude': Icons.calculate_outlined,
      'Critical Thinking': Icons.lightbulb_outline,
      'Leadership': Icons.groups_outlined,
    };
    final Map<String, Color> colors = {
      'Communication': Colors.blue.shade700,
      'Programming': Colors.green.shade700,
      'Aptitude': Colors.orange.shade700,
      'Critical Thinking': Colors.pink.shade700,
      'Leadership': Colors.purple.shade700,
    };
    final color = colors[category] ?? Colors.grey.shade700;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icons[category] ?? Icons.star_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            category,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withAlpha(80), thickness: 1.2)),
        ],
      ),
    );
  }

  // Normalize resource type to a display category label
  String _typeCategory(String type) {
    switch (type.toLowerCase()) {
      case 'video': return '🎬 Videos';
      case 'pdf':
      case 'article':
      case 'document': return '📄 PDF / Articles';
      case 'quiz': return '📝 Quizzes';
      case 'course': return '🎓 Courses';
      default: return '🔗 Other Resources';
    }
  }

  // Build flat list of String (headers) + LearningResource (cards) grouped by type
  List<dynamic> _buildTypeGroupedItems() {
    const order = ['🎬 Videos', '📄 PDF / Articles', '📝 Quizzes', '🎓 Courses', '🔗 Other Resources'];
    final Map<String, List<LearningResource>> grouped = {};
    for (final r in _resources) {
      final cat = _typeCategory(r.type);
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add(r);
    }
    final result = <dynamic>[];
    for (final cat in order) {
      if (grouped.containsKey(cat) && grouped[cat]!.isNotEmpty) {
        result.add(cat);
        result.addAll(grouped[cat]!);
      }
    }
    return result;
  }

  Widget _buildTypeCategoryHeader(String category) {
    final Map<String, Color> colors = {
      '🎬 Videos':          Colors.red.shade700,
      '📄 PDF / Articles':  Colors.blue.shade700,
      '📝 Quizzes':         Colors.purple.shade700,
      '🎓 Courses':         Colors.teal.shade700,
      '🔗 Other Resources': Colors.grey.shade700,
    };
    final Map<String, IconData> icons = {
      '🎬 Videos':          Icons.play_circle_outline,
      '📄 PDF / Articles':  Icons.description_outlined,
      '📝 Quizzes':         Icons.quiz_outlined,
      '🎓 Courses':         Icons.school_outlined,
      '🔗 Other Resources': Icons.link,
    };
    final color = colors[category] ?? Colors.grey.shade700;
    final icon  = icons[category]  ?? Icons.folder_outlined;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            category,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: color.withOpacity(0.35), thickness: 1.2)),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        const Text("Language:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          children: ['English', 'Tamil'].map((lang) {
            final isSelected = _selectedLanguage == lang;
            return ChoiceChip(
              label: Text(lang),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && _selectedLanguage != lang) {
                  setState(() => _selectedLanguage = lang);
                  _loadPlanAndResources();
                }
              },
              selectedColor: Colors.blue.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade900 : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.blue.shade200 : Colors.grey.shade300),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlanHeader() {
    final plan = _planData!;
    final riskLevel = plan['risk_level'] ?? 'Low';
    final focusType = plan['focus_type'] ?? '';
    final units = plan['units'] as String?;
    final skillCategory = plan['skill_category'] as String?;
    final resourceLevel = plan['resource_level'] as String?;

    Color riskColor;
    IconData riskIcon;
    switch (riskLevel) {
      case 'High':
        riskColor = Colors.red.shade700;
        riskIcon = Icons.warning_amber_rounded;
        break;
      case 'Medium':
        riskColor = Colors.orange.shade800;
        riskIcon = Icons.info_outline;
        break;
      default:
        riskColor = Colors.green.shade700;
        riskIcon = Icons.check_circle_outline;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: riskColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Row
                      Row(
                        children: [
                          Icon(riskIcon, color: riskColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Learning Plan",
                            style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              riskLevel.toUpperCase(),
                              style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Plan Details
                      _buildInfoRow("Focus Type", focusType, Icons.track_changes),
                      if (units != null && units.isNotEmpty)
                        _buildInfoRow("Units", "Unit ${units.replaceAll(',', ', ')}", Icons.menu_book),
                      if (skillCategory != null)
                        _buildInfoRow("Skill", skillCategory, Icons.psychology),
                      if (resourceLevel != null)
                        _buildInfoRow("Level", resourceLevel, Icons.signal_cellular_alt),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Extract the first unit if multiple are given, or use a default
                            int unitNum = 1;
                            if (units != null && units.isNotEmpty) {
                              try {
                                unitNum = int.parse(units.split(',').first.trim());
                              } catch (_) {}
                            }
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(
                                  subjectCode: widget.subjectCode,
                                  subjectTitle: widget.subjectTitle,
                                  unitNumber: unitNum,
                                  riskLevel: riskLevel,
                                ),
                              ),
                            ).then((_) => _loadPlanAndResources()); // Refresh after quiz
                          },
                          icon: const Icon(Icons.quiz, size: 18),
                          label: const Text("Take AI-Generated Quiz"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: riskColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700, fontSize: 13)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeScheduleSection() {
    final schedule = _planData!['practice_schedule'] is Map<String, dynamic> ? _planData!['practice_schedule'] : <String, dynamic>{};
    final type = schedule['type'] ?? 'weekly';
    final items = schedule['schedule'] is List ? schedule['schedule'] as List<dynamic> : [];
    final focus = schedule['focus'] as String? ?? '';

    final isDaily = type == 'daily';
    final headerColor = isDaily ? Colors.red : Colors.orange;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isDaily ? Icons.calendar_today : Icons.date_range,
                    color: headerColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  isDaily ? 'Daily Practice Plan' : 'Weekly Improvement Plan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: headerColor),
                ),
              ],
            ),
            if (focus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: headerColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.track_changes, size: 14, color: headerColor.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        focus,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final dayOrWeek = isDaily ? (item['day'] ?? '') : 'Week ${item['week'] ?? ''}';
              final task = item['task'] ?? '';
              final isLast = index == items.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: headerColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: headerColor, width: 2),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: headerColor.withOpacity(0.3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayOrWeek,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgress() {
    // Assuming _planData doesn't contain the raw progress fraction, we compute it locally based on the resources
    int completedCount = _resources.where((r) => r.isCompleted).length;
    int totalCount = _resources.length;
    double percent = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return CircularPercentIndicator(
      radius: 20.0,
      lineWidth: 4.0,
      percent: percent,
      center: Text(
        "${(percent * 100).toInt()}%",
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      progressColor: percent >= 1.0 ? Colors.green : Colors.blue,
      backgroundColor: Colors.grey.shade200,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 800,
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.library_books_outlined, size: 48, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              "No resources assigned",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              "Your learning plan will assign resources when data is available.",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(LearningResource resource) {
    Color typeColor;
    IconData typeIcon;

    switch (resource.type.toLowerCase()) {
      case 'video':
        typeColor = Colors.red.shade600;
        typeIcon = Icons.play_circle_fill;
        break;
      case 'pdf':
      case 'document':
      case 'article':
        typeColor = Colors.blue.shade600;
        typeIcon = Icons.description;
        break;
      case 'quiz':
        typeColor = Colors.purple.shade600;
        typeIcon = Icons.quiz;
        break;
      case 'course':
        typeColor = Colors.teal.shade600;
        typeIcon = Icons.school;
        break;
      default:
        typeColor = Colors.green.shade600;
        typeIcon = Icons.link;
    }

    return Card(
      elevation: resource.isCompleted ? 1 : 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Opacity(
        opacity: resource.isCompleted ? 0.6 : 1.0,
        child: InkWell(
          onTap: () {
            // All skill development resources now lead to the rich AI-powered content screen
            if (resource.skillCategory != null && resource.skillCategory!.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SkillContentScreen(resource: resource),
                ),
              ).then((_) => setState(() {}));
            } else if (resource.url == 'internal') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SkillContentScreen(resource: resource),
                ),
              ).then((_) => setState(() {}));
            } else if (resource.type.toLowerCase() == 'video') {
              _playResource(resource);
            } else {
              _launchUrl(resource.url);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: resource.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  resource.type.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: typeColor),
                                ),
                              ),
                              if (resource.unit != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Unit ${resource.unit}",
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade700),
                                  ),
                                ),
                              if (resource.resourceLevel != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    resource.resourceLevel!,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.amber.shade800),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        resource.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: resource.isCompleted
                            ? Colors.green
                            : Colors.grey.shade400,
                        size: 28,
                      ),
                      onPressed: () => _toggleResourceCompletion(resource),
                      tooltip: resource.isCompleted
                          ? "Mark as incomplete"
                          : "Mark as completed",
                    ),
                  ],
                ),
                if (_playingResourceId == resource.resourceId &&
                    _ytController != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: YoutubePlayer(
                      controller: _ytController!,
                      aspectRatio: 16 / 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
