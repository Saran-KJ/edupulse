import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class LearningResourcesScreen extends StatefulWidget {
  final String subjectCode;
  final String subjectTitle;

  const LearningResourcesScreen({
    Key? key,
    required this.subjectCode,
    required this.subjectTitle,
  }) : super(key: key);

  @override
  _LearningResourcesScreenState createState() => _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  bool _isLoading = true;
  List<LearningResource> _resources = [];
  String? _error;

  Map<String, dynamic>? _riskContext;
  String _selectedLanguage = "English";

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getLearningRecommendations(
        subjectCode: widget.subjectCode,
        language: _selectedLanguage,
      );
      final list = data['resources'] as List<dynamic>? ?? [];
      setState(() {
        _resources = list.map((json) => LearningResource.fromJson(json)).toList();
        _riskContext = data['risk_context'];
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch resource URL: $url')),
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
        title: Text(
          widget.subjectTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[200],
            height: 1.0,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Determine if we should use a wide layout (e.g. tablet/desktop)
                    final isWide = constraints.maxWidth > 600;
                    
                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                         SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFilterSection(),
                                const SizedBox(height: 16),
                                if (_riskContext != null) _buildRiskBanner(isWide),
                                const SizedBox(height: 24),
                                Text(
                                  "Recommended Resources",
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        if (_resources.isEmpty)
                          SliverToBoxAdapter(child: _buildEmptyState())
                        else
                          isWide
                              ? SliverGrid(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
                                    childAspectRatio: 1.5,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildResourceCard(_resources[index]),
                                    childCount: _resources.length,
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      child: _buildResourceCard(_resources[index]),
                                    ),
                                    childCount: _resources.length,
                                  ),
                                ),
                         const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                      ],
                    );
                  },
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
                  _loadResources();
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
                side: BorderSide(
                  color: isSelected ? Colors.blue.shade200 : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRiskBanner(bool isWide) {
    String level = _riskContext?['level'] ?? 'Low';
    Color color;
    IconData icon;
    String title;
    String message;

    switch (level) {
      case 'High':
        color = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
        title = "Needs Attention";
        message = "We recommmend starting with basic concepts and short videos.";
        break;
      case 'Medium':
        color = Colors.orange.shade800;
        icon = Icons.info_outline;
        title = "Moderate Risk";
        message = "Focus on topic-wise revision and practice questions.";
        break;
      default:
        color = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        title = "On Track";
        message = "Great progress! Try advanced topics to challenge yourself.";
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
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
              Container(
                width: 6,
                color: color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: color, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                           if (_riskContext?['score'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Score: ${(_riskContext!['score'] as num).toStringAsFixed(0)}%",
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                      if (level == 'High') ...[
                        const SizedBox(height: 12),
                        if (isWide)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.quiz, size: 18),
                              label: const Text("Take Practice Quiz"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Launching Practice Quiz...")),
                                );
                              },
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.quiz, size: 18),
                              label: const Text("Take Practice Quiz"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Launching Practice Quiz...")),
                                );
                              },
                            ),
                          ),
                      ],
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
              "No resources found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
             const SizedBox(height: 8),
             Text(
              "Try selecting a different language or check back later.",
              style: TextStyle(color: Colors.grey.shade600),
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
        typeColor = Colors.blue.shade600;
        typeIcon = Icons.description;
        break;
      case 'quiz':
        typeColor = Colors.purple.shade600;
        typeIcon = Icons.quiz;
        break;
      default:
        typeColor = Colors.green.shade600;
        typeIcon = Icons.link;
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _launchUrl(resource.url),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              resource.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (resource.description != null)
                Expanded(
                  child: Text(
                    resource.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                )
              else 
                const Spacer(),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (resource.tags != null)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: resource.tags!.split(',').take(2).map((tag) => 
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag.trim(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            )
                          ).toList(),
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

