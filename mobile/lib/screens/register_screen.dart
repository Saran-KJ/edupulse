import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final String? selectedRole;
  
  const RegisterScreen({super.key, this.selectedRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _regNoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sectionController = TextEditingController();
  // Parent-specific controllers
  final _childNameController = TextEditingController();
  final _childPhoneController = TextEditingController();
  final _childRegNoController = TextEditingController();
  final _occupationController = TextEditingController();
  
  String? _selectedDept;
  String? _selectedYear;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isStudent => widget.selectedRole == 'Student' || widget.selectedRole == null;
  bool get _isClassAdvisor => widget.selectedRole == 'Class Advisor';
  bool get _isParent => widget.selectedRole == 'Parent';
  bool get _isFaculty => widget.selectedRole == 'Faculty';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _regNoController.dispose();
    _phoneController.dispose();
    _sectionController.dispose();
    // Dispose parent controllers
    _childNameController.dispose();
    _childPhoneController.dispose();
    _childRegNoController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final role = widget.selectedRole ?? 'Student';
      final backendRole = _mapRoleToBackendFormat(role);
      
      await ApiService().register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        backendRole,
        regNo: _regNoController.text.trim(),
        phone: _phoneController.text.trim(),
        dept: _selectedDept,
        year: _selectedYear,
        section: _sectionController.text.trim(),
        // Parent-specific fields
        childName: _childNameController.text.trim(),
        childPhone: _childPhoneController.text.trim(),
        childRegNo: _childRegNoController.text.trim(),
        occupation: _occupationController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please wait for admin approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapRoleToBackendFormat(String uiRole) {
    switch (uiRole) {
      case 'Student':
        return 'student';
      case 'Class Advisor':
        return 'class_advisor';
      case 'Faculty':
        return 'faculty';
      case 'HOD':
        return 'hod';
      case 'Vice Principal':
        return 'vice_principal';
      case 'Principal':
        return 'principal';
      case 'Admin':
        return 'admin';
      case 'Parent':
        return 'parent';
      default:
        return 'student';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final boxSize = screenSize.width > 600 ? 450.0 : screenSize.width * 0.9;

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      Icons.person_add,
                      size: 50,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join EduPulse Today',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Register Box
                  Container(
                    width: boxSize,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
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
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              // Allow only alphabets and dots
                              final nameRegExp = RegExp(r'^[a-zA-Z .]+$');
                              if (!nameRegExp.hasMatch(value)) {
                                return 'Only alphabets and dots are allowed';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Parent-specific fields: Child's Name
                          if (_isParent) ...[
                            TextFormField(
                              controller: _childNameController,
                              decoration: InputDecoration(
                                labelText: "Child's Name",
                                prefixIcon: const Icon(Icons.child_care),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (_isParent && (value == null || value.isEmpty)) {
                                  return "Please enter your child's name";
                                }
                                final nameRegExp = RegExp(r'^[a-zA-Z .]+$');
                                if (value != null && value.isNotEmpty && !nameRegExp.hasMatch(value)) {
                                  return 'Only alphabets and dots are allowed';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Child's Register Number
                            TextFormField(
                              controller: _childRegNoController,
                              decoration: InputDecoration(
                                labelText: "Child's Register Number",
                                prefixIcon: const Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                helperText: 'Enter student register number (e.g., 2021CSE001)',
                              ),
                              validator: (value) {
                                if (_isParent && (value == null || value.isEmpty)) {
                                  return "Please enter your child's register number";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Child's Phone Number
                            TextFormField(
                              controller: _childPhoneController,
                              decoration: InputDecoration(
                                labelText: "Child's Phone Number",
                                prefixIcon: const Icon(Icons.phone_android),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                helperText: 'Enter 10-digit mobile number (for matching)',
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              validator: (value) {
                                if (_isParent) {
                                  if (value == null || value.isEmpty) {
                                    return "Please enter your child's phone number";
                                  }
                                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                    return 'Phone number should contain only digits';
                                  }
                                  if (value.length != 10) {
                                    return 'Phone number must be exactly 10 digits';
                                  }
                                  if (!RegExp(r'^[6-9]').hasMatch(value)) {
                                    return 'Phone number must start with 6, 7, 8, or 9';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Register Number Field
                          if (_isStudent) ...[
                            TextFormField(
                              controller: _regNoController,
                              decoration: InputDecoration(
                                labelText: 'Register Number',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (_isStudent && (value == null || value.isEmpty)) {
                                  return 'Please enter your register number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Mobile Number Field
                          if (_isStudent) ...[
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Mobile Number',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                helperText: 'Enter 10-digit mobile number',
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              validator: (value) {
                                if (_isStudent) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your mobile number';
                                  }
                                  // Check if it contains only digits
                                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                    return 'Mobile number should contain only digits';
                                  }
                                  // Check if length is exactly 10
                                  if (value.length != 10) {
                                    return 'Mobile number must be exactly 10 digits';
                                  }
                                  // Check if it starts with 6, 7, 8, or 9
                                  if (!RegExp(r'^[6-9]').hasMatch(value)) {
                                    return 'Mobile number must start with 6, 7, 8, or 9';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Mobile Number Field for Parent
                          if (_isParent) ...[
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Your Mobile Number',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                helperText: 'Enter 10-digit mobile number',
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              validator: (value) {
                                if (_isParent) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your mobile number';
                                  }
                                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                    return 'Mobile number should contain only digits';
                                  }
                                  if (value.length != 10) {
                                    return 'Mobile number must be exactly 10 digits';
                                  }
                                  if (!RegExp(r'^[6-9]').hasMatch(value)) {
                                    return 'Mobile number must start with 6, 7, 8, or 9';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Occupation Field
                            TextFormField(
                              controller: _occupationController,
                              decoration: InputDecoration(
                                labelText: 'Occupation',
                                prefixIcon: const Icon(Icons.work_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (_isParent && (value == null || value.isEmpty)) {
                                  return 'Please enter your occupation';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Department Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDept,
                            decoration: InputDecoration(
                              labelText: 'Department',
                              prefixIcon: const Icon(Icons.school_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: ['CSE', 'ECE', 'MECH', 'CIVIL', 'EEE', 'IT', 'AI&DS']
                                .map((dept) => DropdownMenuItem(
                                      value: dept,
                                      child: Text(dept),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDept = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Please select a department' : null,
                          ),
                          const SizedBox(height: 16),

                          // Year Dropdown
                          if (_isStudent || _isClassAdvisor || _isParent || _isFaculty) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _selectedYear,
                              decoration: InputDecoration(
                                labelText: 'Year',
                                prefixIcon: const Icon(Icons.calendar_today_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              items: ['1', '2', '3', '4']
                                  .map((year) => DropdownMenuItem(
                                        value: year,
                                        child: Text('Year $year'),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedYear = value),
                              validator: (value) {
                                if ((_isStudent || _isClassAdvisor || _isParent || _isFaculty) && value == null) {
                                  return 'Please select a year';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Section Field (Conditional)
                          if (_selectedDept == 'CSE' || _isFaculty) ...[
                            TextFormField(
                              controller: _sectionController,
                              decoration: InputDecoration(
                                labelText: 'Section',
                                prefixIcon: const Icon(Icons.class_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if ((_selectedDept == 'CSE' || _isFaculty) &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter your section';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 16),
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
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
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
