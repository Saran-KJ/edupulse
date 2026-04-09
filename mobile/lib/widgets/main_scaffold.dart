import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import 'responsive_layout.dart';

/// Unified navigation item for all scaffold types
class NavDestination {
  final IconData icon;
  final String label;
  final Widget? badge;

  const NavDestination({
    required this.icon,
    required this.label,
    this.badge,
  });
}

/// A premium, responsive scaffold that adapts its navigation based on screen size.
/// - Desktop/Tablet: Side Navigation Bar (Rail or Sidebar)
/// - Mobile: Bottom Navigation Bar
class MainScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final List<NavDestination> destinations;
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final Widget? userHeader;
  final VoidCallback? onLogout;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;

  final String? userName;
  final String? userRole;
  final VoidCallback? onProfileTap;

  const MainScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.userHeader,
    this.onLogout,
    this.actions,
    this.floatingActionButton,
    this.userName,
    this.userRole,
    this.onProfileTap,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileScaffold(context),
      tablet: _buildDesktopScaffold(context),
      desktop: _buildDesktopScaffold(context),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: widget.body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: NavigationBar(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withValues(alpha: 0.1),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: widget.destinations.map((d) => NavigationDestination(
              icon: Icon(d.icon, color: AppColors.textSecondary),
              selectedIcon: Icon(d.icon, color: AppColors.primary),
              label: d.label,
            )).toList(),
          ),
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildDesktopScaffold(BuildContext context) {
    final bool isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    return Scaffold(
      body: Row(
        children: [
          // Adaptive Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            width: _isSidebarExpanded ? 280 : 80,
            child: _buildSidebar(isDesktop),
          ),
          // Main Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildTopBar(context),
                // Content with Constraints
                Expanded(
                  child: Container(
                    color: AppColors.surface,
                    child: ContentConstraints(
                      maxWidth: 1400,
                      padding: const EdgeInsets.all(24),
                      child: widget.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_isSidebarExpanded) 
            IconButton(
              icon: const Icon(Icons.menu_open_rounded),
              onPressed: () => setState(() => _isSidebarExpanded = true),
            ),
          Expanded(
            child: Text(
              widget.title,
              style: AppTextStyles.heading.copyWith(fontSize: 20),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.actions != null) ...widget.actions!,
          const SizedBox(width: 16),
          // User Profile Dropdown Placeholder
          _buildTopBarProfile(),
        ],
      ),
    );
  }

  Widget _buildTopBarProfile() {
    return PopupMenuButton<int>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      onSelected: (value) {
        if (value == 0 && widget.onProfileTap != null) {
          widget.onProfileTap!();
        } else if (value == 1 && widget.onLogout != null) {
          widget.onLogout!();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName ?? 'User Name',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
              ),
              Text(
                widget.userRole?.replaceAll('_', ' ').toUpperCase() ?? 'ROLE',
                style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.primary),
              ),
              const Divider(),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text('My Profile', style: AppTextStyles.body),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 12),
              Text('Sign Out', style: AppTextStyles.body.copyWith(color: AppColors.error)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                (widget.userName?.isNotEmpty == true) ? widget.userName![0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.sidebar,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Section
          _buildSidebarHeader(),
          
          const SizedBox(height: 20),
          
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.destinations.length,
              itemBuilder: (context, index) {
                final d = widget.destinations[index];
                final isSelected = widget.selectedIndex == index;
                return _buildSidebarItem(d, index, isSelected);
              },
            ),
          ),

          // Footer / User Section
          if (widget.onLogout != null)
            _buildSidebarItem(
              const NavDestination(icon: Icons.logout_rounded, label: 'Sign Out'),
              -1,
              false,
              onTap: widget.onLogout,
            ),
            
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/images/logo.png', width: 28, height: 28),
          ),
          if (_isSidebarExpanded) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'EduPulse',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_double_arrow_left, color: Colors.white54, size: 20),
              onPressed: () => setState(() => _isSidebarExpanded = false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarItem(NavDestination d, int index, bool isSelected, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap ?? () => widget.onDestinationSelected(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: _isSidebarExpanded ? 16 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected 
              ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)
              : null,
          ),
          child: Row(
            mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                d.icon,
                color: isSelected ? Colors.white : Colors.white60,
                size: 22,
              ),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    d.label,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (d.badge != null) d.badge!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
