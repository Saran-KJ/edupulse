import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_theme.dart';
import '../services/api_service.dart';

import 'register_screen.dart';
import 'forgot_password_screen.dart';
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: Stack(
          children: [
            // Floating decorative shapes
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
            Positioned(
              top: screenSize.height * 0.5,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Back Button
                  if (widget.selectedRole != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),

                  // Scrollable Content
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: SlideTransition(
                          position: _slideUp,
                          child: FadeTransition(
                            opacity: _fadeIn,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo
                                Container(
                                  padding: const EdgeInsets.all(18),
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
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Title
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

                                // Role Badge
                                if (widget.selectedRole != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getRoleIcon(widget.selectedRole!),
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.selectedRole!,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                if (widget.selectedRole == null)
                                  Text(
                                    'Student Performance Management',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white60,
                                    ),
                                  ),
                                const SizedBox(height: 36),

                                // Glassmorphism Login Card
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                    child: Container(
                                      width: boxSize,
                                      padding: const EdgeInsets.all(28),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 30,
                                            offset: const Offset(0, 15),
                                          ),
                                        ],
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Welcome Back',
                                              style: GoogleFonts.poppins(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Sign in to continue',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 28),

                                            // Email Field
                                            TextFormField(
                                              controller: _emailController,
                                              decoration: InputDecoration(
                                                labelText: 'Email',
                                                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryLight, size: 20),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                              ),
                                              keyboardType: TextInputType.emailAddress,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your email';
                                                }
                                                if (!value.contains('@')) {
                                                  return 'Please enter a valid email';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 18),

                                            // Password Field
                                            TextFormField(
                                              controller: _passwordController,
                                              decoration: InputDecoration(
                                                labelText: 'Password',
                                                prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.primaryLight, size: 20),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscurePassword
                                                        ? Icons.visibility_off_outlined
                                                        : Icons.visibility_outlined,
                                                    size: 20,
                                                    color: AppColors.textHint,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscurePassword = !_obscurePassword;
                                                    });
                                                  },
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                              ),
                                              obscureText: _obscurePassword,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your password';
                                                }
                                                return null;
                                              },
                                            ),

                                            // Forgot Password Link
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => const ForgotPasswordScreen(),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Forgot Password?',
                                                  style: GoogleFonts.inter(
                                                    color: AppColors.primaryLight,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            // Gradient Login Button
                                            SizedBox(
                                              width: double.infinity,
                                              height: 52,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: AppGradients.primarySubtle,
                                                  borderRadius: BorderRadius.circular(14),
                                                  boxShadow: _isLoading ? [] : AppShadows.colored(AppColors.primary),
                                                ),
                                                child: ElevatedButton(
                                                  onPressed: _isLoading ? null : _login,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    shadowColor: Colors.transparent,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                  ),
                                                  child: _isLoading
                                                      ? const SizedBox(
                                                          height: 22,
                                                          width: 22,
                                                          child: CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2.5,
                                                          ),
                                                        )
                                                      : Text(
                                                          'Sign In',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 20),

                                            // Conditionally show Register button
                                            if (_canSelfRegister(widget.selectedRole)) ...[
                                              Row(
                                                children: [
                                                  Expanded(child: Divider(color: Colors.grey.shade300)),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                                    child: Text(
                                                      'OR',
                                                      style: GoogleFonts.inter(
                                                        color: AppColors.textHint,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(child: Divider(color: Colors.grey.shade300)),
                                                ],
                                              ),

                                              const SizedBox(height: 20),

                                              SizedBox(
                                                width: double.infinity,
                                                height: 52,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => RegisterScreen(selectedRole: widget.selectedRole),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Create Account',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
