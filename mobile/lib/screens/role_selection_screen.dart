import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school,
                        size: 50,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'EduPulse',
                      style: TextStyle(
                        fontSize: 36,
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
              
              // Role Cards
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildRoleCard(
                        context,
                        role: 'Student',
                        icon: Icons.person,
                        description: 'Access your courses and performance',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        role: 'Class Advisor',
                        icon: Icons.supervisor_account,
                        description: 'Monitor and guide your class',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        role: 'Faculty',
                        icon: Icons.school_outlined,
                        description: 'Manage courses and students',
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        role: 'HOD',
                        icon: Icons.business_center,
                        description: 'Head of Department access',
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        role: 'Vice Principal',
                        icon: Icons.admin_panel_settings,
                        description: 'Administrative oversight',
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        role: 'Principal',
                        icon: Icons.account_balance,
                        description: 'Complete institutional control',
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        role: 'Admin',
                        icon: Icons.security,
                        description: 'System administration',
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildRoleCard(
    BuildContext context, {
    required String role,
    required IconData icon,
    required String description,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(selectedRole: role),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
            
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
