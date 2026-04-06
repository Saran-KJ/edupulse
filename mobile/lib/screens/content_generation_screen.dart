import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ContentGenerationScreen extends StatefulWidget {
  @override
  _ContentGenerationScreenState createState() =>
      _ContentGenerationScreenState();
}

class _ContentGenerationScreenState extends State<ContentGenerationScreen> {
  final ApiService apiService = ApiService();
  
  // Form controllers
  late TextEditingController subjectController;
  late TextEditingController topicController;
  int selectedUnit = 1;
  String selectedPreference = 'text';

  LearningContent? generatedContent;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    subjectController = TextEditingController();
    topicController = TextEditingController();
  }

  @override
  void dispose() {
    subjectController.dispose();
    topicController.dispose();
    super.dispose();
  }

  void generateContent() async {
    if (subjectController.text.isEmpty || topicController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final content = await apiService.generateContent(
        subjectName: subjectController.text,
        unitNumber: selectedUnit,
        topic: topicController.text,
        learningPreference: selectedPreference,
      );

      setState(() {
        generatedContent = content;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learning Content Generator'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            SizedBox(height: 16),
            Text(
              'Content Generation Form',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            // Subject Input
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Data Structures, Database Systems',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
            ),
            SizedBox(height: 16),
            // Topic Input
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: 'Topic',
                hintText: 'e.g., Binary Search Trees',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.topic),
              ),
            ),
            SizedBox(height: 16),
            // Unit Selection
            Text('Unit Number'),
            SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [1, 2, 3, 4, 5].map((unit) {
                return ButtonSegment(
                  value: unit,
                  label: Text('Unit $unit'),
                );
              }).toList(),
              selected: {selectedUnit},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  selectedUnit = newSelection.first;
                });
              },
            ),
            SizedBox(height: 16),
            // Learning Preference
            Text('Learning Preference'),
            SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedPreference,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'text', child: Text('Text-based')),
                DropdownMenuItem(value: 'visual', child: Text('Visual')),
                DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPreference = value;
                  });
                }
              },
            ),
            SizedBox(height: 24),
            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : generateContent,
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.auto_awesome),
                label: Text(isLoading
                    ? 'Loading...'
                    : 'Generate Content'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 24),
            // Display Generated Content
            if (generatedContent != null) ...[
              ContentDisplayWidget(content: generatedContent!),
            ],
          ],
        ),
      ),
    );
  }
}

class ContentDisplayWidget extends StatelessWidget {
  final LearningContent content;

  const ContentDisplayWidget({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(thickness: 2),
        SizedBox(height: 16),
        Text(
          'Generated Content',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 16),
        // Title
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text('Unit ${content.unit}'),
                      backgroundColor: Colors.blue.shade100,
                    ),
                    SizedBox(width: 8),
                    Chip(
                      label: Text(content.difficultyLevel),
                      backgroundColor: Colors.orange.shade100,
                    ),
                    SizedBox(width: 8),
                    Chip(
                      label: Text(content.estimatedReadTime),
                      backgroundColor: Colors.green.shade100,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        // Learning Objectives
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Objectives',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 12),
                ...content.learningObjectives.asMap().entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}. ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(entry.value),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        // Introduction
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Introduction',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 12),
                Text(content.introduction),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        // Sections
        ...content.sections.asMap().entries.map((entry) {
          final section = entry.value;
          final index = entry.key;
          return Column(
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Section ${index + 1}: ${section.title}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        section.content,
                        style: TextStyle(height: 1.6),
                      ),
                      if (section.keyPoints.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'Key Points:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        ...section.keyPoints.map((point) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: TextStyle(fontSize: 18)),
                                Expanded(child: Text(point)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      if (section.examples != null &&
                          section.examples!.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'Examples:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        ...section.examples!.map((example) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('→ ', style: TextStyle(fontSize: 18)),
                                Expanded(child: Text(example)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          );
        }).toList(),
        // Summary
        Card(
          elevation: 2,
          color: Colors.green.shade50,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                ),
                SizedBox(height: 12),
                Text(content.summary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
