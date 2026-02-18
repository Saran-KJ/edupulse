import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../widgets/responsive_layout.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= ResponsiveBreakpoints.tablet;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.purple.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(isWideScreen ? 32.0 : 24.0),
                child: Column(
                  children: [
                    SizedBox(height: isWideScreen ? 30 : 20),
                    Container(
                      padding: EdgeInsets.all(isWideScreen ? 24 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school,
                        size: isWideScreen ? 60 : 50,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: isWideScreen ? 24 : 20),
                    Text(
                      'EduPulse',
                      style: TextStyle(
                        fontSize: isWideScreen ? 42 : 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select Your Role',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Role Cards - Responsive grid
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 48.0 : 24.0,
                    vertical: 8,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: _buildRoleGrid(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleGrid(BuildContext context) {
    final roles = [
      {'role': 'Student', 'icon': Icons.person, 'description': 'Access your courses and performance', 'color': Colors.blue},
      {'role': 'Parent', 'icon': Icons.family_restroom, 'description': 'Monitor your child\'s progress', 'color': Colors.teal},
      {'role': 'Class Advisor', 'icon': Icons.supervisor_account, 'description': 'Monitor and guide your class', 'color': Colors.green},
      {'role': 'Faculty', 'icon': Icons.school_outlined, 'description': 'Manage courses and students', 'color': Colors.orange},
      {'role': 'HOD', 'icon': Icons.business_center, 'description': 'Head of Department access', 'color': Colors.purple},
      {'role': 'Vice Principal', 'icon': Icons.admin_panel_settings, 'description': 'Administrative oversight', 'color': Colors.indigo},
      {'role': 'Principal', 'icon': Icons.account_balance, 'description': 'Complete institutional control', 'color': Colors.red},
      {'role': 'Admin', 'icon': Icons.security, 'description': 'System administration', 'color': Colors.blueGrey},
    ];

    final crossAxisCount = ResponsiveBreakpoints.getCrossAxisCount(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 4,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: crossAxisCount == 1 ? 3.2 : 1.4,
      ),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final data = roles[index];
        return _buildRoleCard(
          context,
          role: data['role'] as String,
          icon: data['icon'] as IconData,
          description: data['description'] as String,
          color: data['color'] as Color,
          isCompact: crossAxisCount > 1,
        );
      },
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String role,
    required IconData icon,
    required String description,
    required Color color,
    bool isCompact = false,
  }) {
    return HoverScaleEffect(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(selectedRole: role),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: isCompact ? _buildCompactContent(role, icon, description, color) : _buildFullContent(role, icon, description, color),
      ),
    );
  }

  Widget _buildCompactContent(String role, IconData icon, String description, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          role,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFullContent(String role, IconData icon, String description, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                role,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey.shade400,
        ),
      ],
    );
  }
}
