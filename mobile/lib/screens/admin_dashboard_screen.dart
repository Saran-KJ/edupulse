import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_scaffold.dart';
import 'role_selection_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = ApiService();

  String _selectedFilterRole = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _logout() async {
    await _apiService.clearToken();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;

    final tabContent = TabBarView(
      controller: _tabController,
      children: [
        _buildUserManagementTab(),
        _buildApprovalsTab(),
        _buildLogsTab(),
      ],
    );

    if (isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade800, Colors.blue.shade900],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.admin_panel_settings, size: 28, color: Colors.blue.shade800),
                        ),
                        const SizedBox(width: 12),
                        const Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  _buildSideNavItem(Icons.people, 'Users', 0),
                  _buildSideNavItem(Icons.verified_user, 'Approvals', 1),
                  _buildSideNavItem(Icons.security, 'Logs', 2),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white70),
                    title: const Text('Logout', style: TextStyle(color: Colors.white70)),
                    onTap: _logout,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Text(_getTabTitle(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (_tabController.index == 0)
                          ElevatedButton.icon(
                            onPressed: _showCreateUserDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add User'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                          ),
                      ],
                    ),
                  ),
                  Expanded(child: Container(color: Colors.grey.shade50, child: tabContent)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.verified_user), text: 'Approvals'),
            Tab(icon: Icon(Icons.security), text: 'Logs'),
          ],
        ),
      ),
      body: tabContent,
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showCreateUserDialog,
              backgroundColor: Colors.blue.shade800,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  String _getTabTitle() {
    switch (_tabController.index) {
      case 0: return 'User Management';
      case 1: return 'Pending Approvals';
      case 2: return 'Login Logs';
      default: return 'Admin Dashboard';
    }
  }

  Widget _buildSideNavItem(IconData icon, String label, int index) {
    final isSelected = _tabController.index == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _tabController.animateTo(index)),
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 22),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- User Management Tab ---
  Widget _buildUserManagementTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Role Filter
              DropdownButtonFormField<String>(
                value: _selectedFilterRole,
                decoration: InputDecoration(
                  labelText: 'Filter by Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.filter_list),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: ['All', 'Student', 'Faculty', 'Class Advisor', 'HOD', 'Vice Principal', 'Principal', 'Admin']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilterRole = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search by name, email, dept...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<User>>(
            future: _apiService.getUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              var users = snapshot.data ?? [];
              
              // Apply Role Filter
              if (_selectedFilterRole != 'All') {
                users = users.where((user) => 
                  user.role.toLowerCase() == _selectedFilterRole.toLowerCase().replaceAll(' ', '_')
                ).toList();
              }
              
              // Apply Search Filter
              if (_searchQuery.isNotEmpty) {
                users = users.where((user) {
                  final name = user.name.toLowerCase();
                  final email = user.email.toLowerCase();
                  final dept = user.dept?.toLowerCase() ?? '';
                  final regNo = user.regNo?.toLowerCase() ?? '';
                  
                  return name.contains(_searchQuery) || 
                         email.contains(_searchQuery) ||
                         dept.contains(_searchQuery) ||
                         regNo.contains(_searchQuery);
                }).toList();
              }
              
              if (users.isEmpty) {
                return const Center(child: Text('No users found'));
              }
              
              return ListView.builder(
                itemCount: users.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.isActive == 1 ? Colors.green : Colors.grey,
                        child: Icon(
                          _getRoleIcon(user.role),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: _buildUserSubtitle(user),
                      isThreeLine: true,
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: const Text('Edit'),
                            onTap: () => Future.delayed(
                              Duration.zero,
                              () => _showEditUserDialog(user),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(user.isActive == 1 ? 'Disable' : 'Enable'),
                            onTap: () => _toggleUserStatus(user.userId),
                          ),
                          PopupMenuItem(
                            value: 'reset',
                            child: const Text('Reset Password'),
                            onTap: () => Future.delayed(
                              Duration.zero,
                              () => _showResetPasswordDialog(user),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            onTap: () => _deleteUser(user.userId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserSubtitle(User user) {

    
    // Format: Dept (if exists) then Role
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.dept != null && user.dept!.isNotEmpty) 
          Text('Dept: ${user.dept}', style: const TextStyle(fontSize: 13)),
        
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            user.role.toUpperCase().replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ),
        
        if (user.email.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
      ],
    );
  }

  // --- Approvals Tab ---
  Widget _buildApprovalsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.getPendingUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final pendingUsers = snapshot.data ?? [];
        
        if (pendingUsers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No pending approvals'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: pendingUsers.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final user = pendingUsers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.person_add, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(user['email']),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Text(
                            user['role'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _rejectUser(user['user_id']),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Reject', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveUser(user['user_id']),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Approve', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Logs Tab ---
  Widget _buildLogsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.getLoginLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final logs = snapshot.data ?? [];
        
        return ListView.builder(
          itemCount: logs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final log = logs[index];
            final success = log['success'] == 1;
            final timestamp = DateTime.parse(log['timestamp']);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                title: Text(log['email']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (!success && log['failure_reason'] != null)
                      Text(
                        'Reason: ${log['failure_reason']}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
                trailing: log['ip_address'] != null
                    ? Text(
                        log['ip_address'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  // --- Actions ---
  
  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    final formKey = GlobalKey<FormState>(); // Added form key
    
    // New controllers for conditional fields
    String? selectedDept;
    String? selectedSection;
    String? selectedYear;
    
    String selectedRole = 'Faculty'; // Default to Faculty as it's common
    
    bool obscurePassword = true;
    
    final List<String> departments = ['CSE', 'ECE', 'EEE', 'MECH', 'CIVIL', 'IT', 'AI&DS'];
    final List<String> sections = ['A', 'B', 'C'];
    final List<String> years = ['1', '2', '3', '4'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Logic for showing fields
          bool showDept = ['Faculty', 'Class Advisor', 'HOD'].contains(selectedRole);
          bool showSection = selectedRole == 'Class Advisor' && selectedDept == 'CSE';
          bool showYear = selectedRole == 'Class Advisor';
          
          return AlertDialog(
            title: const Text('Create User'),
            content: SingleChildScrollView(
              child: Form( // Wrapped in Form
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField( // Changed to TextFormField
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) { // Added validator
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        final nameRegExp = RegExp(r'^[a-zA-Z .]+$');
                        if (!nameRegExp.hasMatch(value)) {
                          return 'Only alphabets and dots are allowed';
                        }
                        return null;
                      },
                    ),
                    TextFormField( // Changed to TextFormField for consistency
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextFormField( // Changed to TextFormField
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: obscurePassword,
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'Faculty', child: Text('Faculty')),
                      DropdownMenuItem(value: 'Class Advisor', child: Text('Class Advisor')),
                      DropdownMenuItem(value: 'HOD', child: Text('HOD')),
                      DropdownMenuItem(value: 'Vice Principal', child: Text('Vice Principal')),
                      DropdownMenuItem(value: 'Principal', child: Text('Principal')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                        // Reset dependent fields if role changes
                        if (!showDept) selectedDept = null;
                        if (!showSection) selectedSection = null;
                        if (!showYear) selectedYear = null;
                      });
                    },
                  ),
                  
                  if (showDept) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedDept,
                      decoration: const InputDecoration(labelText: 'Department'),
                      items: departments.map((dept) => DropdownMenuItem(
                        value: dept,
                        child: Text(dept),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDept = value;
                          // Reset section if dept changes
                          if (selectedDept != 'CSE') selectedSection = null;
                        });
                      },
                    ),
                  ],

                  if (showYear) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedYear,
                      decoration: const InputDecoration(labelText: 'Year'),
                      items: years.map((year) => DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      )).toList(),
                      onChanged: (value) => setState(() => selectedYear = value),
                    ),
                  ],
                  
                  if (showSection) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedSection,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: sections.map((sec) => DropdownMenuItem(
                        value: sec,
                        child: Text(sec),
                      )).toList(),
                      onChanged: (value) => setState(() => selectedSection = value),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) { // Check validation
                    try {
                      await _apiService.createUser({
                      'name': nameController.text,
                      'email': emailController.text,
                      'password': passwordController.text,
                      'role': _mapRoleToBackend(selectedRole),
                      'dept': selectedDept,
                      'section': selectedSection,
                      'year': selectedYear,
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    setState(() {}); // Refresh list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User created successfully')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } // End if validation
              },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    ).then((_) => setState(() {}));
  }

  void _showEditUserDialog(User user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.updateUser(user.userId, {
                  'name': nameController.text,
                  'email': emailController.text,
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User updated successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => setState(() {}));
  }

  void _showResetPasswordDialog(User user) {
    final passwordController = TextEditingController();
    bool obscureResetPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Reset Password for ${user.name}'),
            content: TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureResetPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureResetPassword = !obscureResetPassword;
                    });
                  },
                ),
              ),
              obscureText: obscureResetPassword,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _apiService.resetUserPassword(
                      user.userId,
                      passwordController.text,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset successfully')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Reset'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleUserStatus(int userId) async {
    try {
      await _apiService.toggleUserStatus(userId);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteUser(userId);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _approveUser(int userId) async {
    try {
      await _apiService.approveUser(userId);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectUser(int userId) async {
    try {
      await _apiService.rejectUser(userId);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _mapRoleToBackend(String uiRole) {
    switch (uiRole) {
      case 'Faculty': return 'faculty';
      case 'Class Advisor': return 'class_advisor';
      case 'HOD': return 'hod';
      case 'Vice Principal': return 'vice_principal';
      case 'Principal': return 'principal';
      case 'Admin': return 'admin';
      default: return 'student';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'student': return Icons.person;
      case 'class advisor': return Icons.supervisor_account;
      case 'faculty': return Icons.school_outlined;
      case 'hod': return Icons.business_center;
      case 'vice principal': return Icons.admin_panel_settings;
      case 'principal': return Icons.account_balance;
      case 'admin': return Icons.security;
      default: return Icons.person;
    }
  }
}
