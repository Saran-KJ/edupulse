import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import '../config/app_theme.dart';
import '../widgets/responsive_layout.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= ResponsiveBreakpoints.tablet;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: Stack(
          children: [
            // Decorative floating circles
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              right: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(isWideScreen ? 32.0 : 24.0),
                    child: Column(
                      children: [
                        SizedBox(height: isWideScreen ? 20 : 12),
                        Container(
                          padding: EdgeInsets.all(isWideScreen ? 20 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: isWideScreen ? 50 : 44,
                              height: isWideScreen ? 50 : 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: isWideScreen ? 20 : 16),
                        Text(
                          'EduPulse',
                          style: GoogleFonts.poppins(
                            fontSize: isWideScreen ? 38 : 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select Your Role',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Role Cards
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen ? 48.0 : 20.0,
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
          ],
        ),
      ),
    );
  }

  Widget _buildRoleGrid(BuildContext context) {
    final roles = [
      {'role': 'Student', 'icon': Icons.school_rounded, 'description': 'Access your courses and performance', 'color': const Color(0xFF42A5F5)},
      {'role': 'Parent', 'icon': Icons.family_restroom_rounded, 'description': 'Monitor your child\'s progress', 'color': const Color(0xFF26A69A)},
      {'role': 'Class Advisor', 'icon': Icons.supervisor_account_rounded, 'description': 'Monitor and guide your class', 'color': const Color(0xFF66BB6A)},
      {'role': 'Faculty', 'icon': Icons.cast_for_education_rounded, 'description': 'Manage courses and students', 'color': const Color(0xFFFF7043)},
      {'role': 'HOD', 'icon': Icons.domain_rounded, 'description': 'Head of Department access', 'color': const Color(0xFFAB47BC)},
      {'role': 'Vice Principal', 'icon': Icons.admin_panel_settings_rounded, 'description': 'Administrative oversight', 'color': const Color(0xFF5C6BC0)},
      {'role': 'Principal', 'icon': Icons.account_balance_rounded, 'description': 'Complete institutional control', 'color': const Color(0xFFEF5350)},
      {'role': 'Admin', 'icon': Icons.shield_rounded, 'description': 'System administration', 'color': const Color(0xFF78909C)},
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
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: crossAxisCount == 1 ? 3.5 : 1.4,
      ),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final data = roles[index];
        // Staggered animation per card
        final delay = index / roles.length;
        final animation = CurvedAnimation(
          parent: _staggerController,
          curve: Interval(delay * 0.6, (delay * 0.6 + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - animation.value)),
                child: child,
              ),
            );
          },
          child: _buildRoleCard(
            context,
            role: data['role'] as String,
            icon: data['icon'] as IconData,
            description: data['description'] as String,
            color: data['color'] as Color,
            isCompact: crossAxisCount > 1,
          ),
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
      child: GlassmorphicCard(
        borderRadius: 20,
        opacity: 0.12,
        padding: EdgeInsets.all(isCompact ? 16 : 24),
        child: isCompact
            ? _buildCompactContent(role, icon, description, color)
            : _buildFullContent(role, icon, description, color),
      ),
    );
  }

  Widget _buildCompactContent(String role, IconData icon, String description, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 28, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          role,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white60,
            height: 1.4,
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 30, color: Colors.white),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                role,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
