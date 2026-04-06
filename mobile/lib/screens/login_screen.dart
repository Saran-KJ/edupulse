import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_theme.dart';
import '../services/api_service.dart';

import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'role_selection_screen.dart';
import 'project_batch_allocation_screen.dart';
import 'students_list_screen.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/responsive_layout.dart';
import 'student_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'class_advisor_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'faculty_dashboard_screen.dart';
import 'hod_dashboard_screen.dart';
import 'principal_dashboard_screen.dart';
import 'vice_principal_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? selectedRole;

  const LoginScreen({super.key, this.selectedRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final user = await _apiService.getCurrentUser();

      if (mounted) {
        // Validate role matches selected role
        if (widget.selectedRole != null) {
          final normalizedUserRole = user.role.toLowerCase().replaceAll(' ', '_');
          final normalizedSelectedRole = widget.selectedRole!.toLowerCase().replaceAll(' ', '_');
          
          if (normalizedUserRole != normalizedSelectedRole) {
            // Role mismatch — clear token and show error
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Access denied: Your account is registered as "${user.role}", not "${widget.selectedRole}".'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
            return;
          }
        }

        Widget targetScreen;
        final role = user.role.toLowerCase();
        if (role == 'student') {
          targetScreen = const StudentDashboardScreen();
        } else if (role == 'admin') {
          targetScreen = const AdminDashboardScreen();
        } else if (role == 'parent') {
          targetScreen = const ParentDashboardScreen();
        } else if (role == 'faculty') {
          targetScreen = const FacultyDashboardScreen();
        } else if (role == 'hod') {
          targetScreen = const HODDashboardScreen();
        } else if (role == 'principal') {
          targetScreen = const PrincipalDashboardScreen();
        } else if (role == 'vice_principal') {
          targetScreen = const VicePrincipalDashboardScreen();
        } else {
          targetScreen = const ClassAdvisorDashboardScreen();
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final boxSize = screenSize.width > 600 ? 440.0 : screenSize.width * 0.9;

    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLogin(context, boxSize, screenSize),
        tablet: _buildDesktopLogin(context, boxSize, screenSize),
        desktop: _buildDesktopLogin(context, boxSize, screenSize),
      ),
    );
  }

  Widget _buildMobileLogin(BuildContext context, double boxSize, Size screenSize) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      child: Stack(
        children: [
          _buildDecorativeShapes(screenSize),
          SafeArea(
            child: Column(
              children: [
                 _buildBackButton(context),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildLoginForm(boxSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLogin(BuildContext context, double boxSize, Size screenSize) {
    return Row(
      children: [
        // Branding Pane
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(gradient: AppGradients.primary),
            child: Stack(
              children: [
                _buildDecorativeShapes(screenSize),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogoBadge(70),
                      const SizedBox(height: 32),
                      Text(
                        'EduPulse',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Empowering Academic Excellence\nthrough Smart Analytics',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.selectedRole != null) _buildBackButton(context),
              ],
            ),
          ),
        ),
        // Form Pane
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.surface,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(64.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLoginForm(boxSize),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    if (widget.selectedRole == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeShapes(Size screenSize) {
    return Stack(
      children: [
        Positioned(
          top: -70,
          right: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -90,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoBadge(double size) {
    return Container(
      padding: EdgeInsets.all(size * 0.28),
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
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLoginForm(double boxSize) {
    return SlideTransition(
      position: _slideUp,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            if (MediaQuery.of(context).size.width <= 600) ...[
              _buildLogoBadge(64),
              const SizedBox(height: 20),
              Text(
                'EduPulse',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            if (widget.selectedRole != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (MediaQuery.of(context).size.width > 600 ? AppColors.primary : Colors.white).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (MediaQuery.of(context).size.width > 600 ? AppColors.primary : Colors.white).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getRoleIcon(widget.selectedRole!), size: 16, color: (MediaQuery.of(context).size.width > 600 ? AppColors.primary : Colors.white)),
                    const SizedBox(width: 8),
                    Text(
                      widget.selectedRole!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: (MediaQuery.of(context).size.width > 600 ? AppColors.primary : Colors.white),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            GlassmorphicCard(
              borderRadius: 24,
              opacity: MediaQuery.of(context).size.width > 600 ? 1.0 : 0.95,
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: boxSize,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Welcome Back',
                        style: AppTextStyles.headingMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to continue',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter email' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter password' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Sign In'),
                        ),
                      ),
                      if (_canSelfRegister(widget.selectedRole)) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: AppTextStyles.bodySmall,
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegisterScreen(selectedRole: widget.selectedRole),
                                ),
                              ),
                              child: Text(
                                'Create Account',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Student': return Icons.school_rounded;
      case 'Class Advisor': return Icons.supervisor_account_rounded;
      case 'Faculty': return Icons.cast_for_education_rounded;
      case 'HOD': return Icons.domain_rounded;
      case 'Vice Principal': return Icons.admin_panel_settings_rounded;
      case 'Principal': return Icons.account_balance_rounded;
      case 'Admin': return Icons.shield_rounded;
      case 'Parent': return Icons.family_restroom_rounded;
      default: return Icons.person_rounded;
    }
  }

  bool _canSelfRegister(String? role) {
    if (role == null) return true;
    const highPrivilegeRoles = ['HOD', 'Vice Principal', 'Principal', 'Admin'];
    return !highPrivilegeRoles.contains(role);
  }
}
