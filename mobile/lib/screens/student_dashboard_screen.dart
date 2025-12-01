import 'package:flutter/material.dart';
import 'student_profile_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            'S',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Surya S',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '21CS001',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'CSE - III Year',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final List<Map<String, dynamic>> summaryData = [
      {
        'title': 'Attendance',
        'value': '82%',
        'icon': Icons.calendar_today,
        'color': Colors.blue,
      },
      {
        'title': 'GPA',
        'value': '7.6',
        'icon': Icons.school,
        'color': Colors.green,
      },
      {
        'title': 'Activities',
        'value': '05',
        'icon': Icons.local_activity,
        'color': Colors.orange,
      },
      {
        'title': 'AI Risk',
        'value': 'Medium',
        'subValue': '(63%)',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.redAccent,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: summaryData.length,
      itemBuilder: (context, index) {
        final data = summaryData[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: data['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data['icon'], color: data['color'], size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['value'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (data['subValue'] != null)
                        Text(
                          data['subValue'],
                          style: TextStyle(
                            fontSize: 11,
                            color: data['color'],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        data['title'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'label': 'View Profile',
        'icon': Icons.person_outline,
        'color': Colors.blue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentProfileScreen(),
            ),
          );
        },
      },
      {
        'label': 'View Marks',
        'icon': Icons.assignment_outlined,
        'color': Colors.green,
        'onTap': () => debugPrint('View Marks tapped'),
      },
      {
        'label': 'Attendance',
        'icon': Icons.calendar_today_outlined,
        'color': Colors.orange,
        'onTap': () => debugPrint('Attendance tapped'),
      },
      {
        'label': 'Activities',
        'icon': Icons.local_activity_outlined,
        'color': Colors.purple,
        'onTap': () => debugPrint('Activities tapped'),
      },
      {
        'label': 'Download Report',
        'icon': Icons.download_outlined,
        'color': Colors.red,
        'onTap': () => debugPrint('Download Report tapped'),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: InkWell(
            onTap: action['onTap'],
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action['icon'],
                      color: action['color'],
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    action['label'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
