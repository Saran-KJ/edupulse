import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import 'responsive_layout.dart';

/// Web-optimized scaffold with sidebar navigation for large screens
class WebScaffold extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<NavigationItem> navigationItems;
  final Widget? userHeader;
  final VoidCallback? onLogout;
  final int selectedIndex;
  final FloatingActionButton? floatingActionButton;
  final List<Widget>? actions;

  const WebScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    required this.navigationItems,
    this.userHeader,
    this.onLogout,
    this.selectedIndex = 0,
    this.floatingActionButton,
    this.actions,
  });

  @override
  State<WebScaffold> createState() => _WebScaffoldState();
}

class _WebScaffoldState extends State<WebScaffold> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;

    if (!isWideScreen) {
      // Mobile: Standard scaffold with drawer
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70),
                ),
            ],
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: widget.actions,
        ),
        drawer: _buildDrawer(),
        body: widget.body,
        floatingActionButton: widget.floatingActionButton,
      );
    }

    // Desktop/Tablet: Sidebar layout
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: _isExpanded ? 270 : 72,
            child: _buildSidebar(),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: AppTextStyles.headingSmall),
                          if (widget.subtitle != null)
                            Text(widget.subtitle!, style: AppTextStyles.subtitle),
                        ],
                      ),
                      const Spacer(),
                      if (widget.actions != null) ...widget.actions!,
                    ],
                  ),
                ),
                // Body content
                Expanded(
                  child: Container(
                    color: AppColors.surface,
                    child: widget.body,
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

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.sidebar,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 110,
            padding: EdgeInsets.all(_isExpanded ? 16 : 8),
            child: Row(
              mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(_isExpanded ? 8 : 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: _isExpanded ? 26 : 22,
                    height: _isExpanded ? 26 : 22,
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'EduPulse',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Toggle button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _isExpanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.navigationItems.length,
              itemBuilder: (context, index) {
                final item = widget.navigationItems[index];
                final isSelected = index == widget.selectedIndex;
                return _buildNavItem(item, isSelected);
              },
            ),
          ),
          // User section
          if (widget.userHeader != null && _isExpanded) ...[
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRect(child: widget.userHeader),
            ),
          ],
          // Logout button
          if (widget.onLogout != null)
            _buildNavItem(
              NavigationItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                onTap: widget.onLogout!,
              ),
              false,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 14 : 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? Colors.white : Colors.white60,
                  size: 20,
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.sidebar,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'EduPulse',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.navigationItems[index];
                    final isSelected = index == widget.selectedIndex;
                    return ListTile(
                      leading: Icon(item.icon, color: isSelected ? Colors.white : Colors.white60),
                      title: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        Navigator.pop(context);
                        item.onTap();
                      },
                    );
                  },
                ),
              ),
              if (widget.onLogout != null)
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.white54),
                  title: Text('Logout', style: GoogleFonts.inter(color: Colors.white54)),
                  onTap: widget.onLogout,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation item data class
class NavigationItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
