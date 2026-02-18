import 'package:flutter/material.dart';
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
            ],
          ),
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
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
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 280 : 72,
            child: _buildSidebar(),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
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
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.subtitle != null)
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
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
                    color: Colors.grey.shade50,
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade900,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 120,
            padding: EdgeInsets.all(_isExpanded ? 16 : 8),
            child: Row(
              mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(_isExpanded ? 10 : 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school,
                    size: _isExpanded ? 28 : 24,
                    color: Colors.blue.shade800,
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'EduPulse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Toggle button
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white70,
            ),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
          ),
          const Divider(color: Colors.white24, height: 1),
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
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRect(child: widget.userHeader),
            ),
          ],
          // Logout button
          if (widget.onLogout != null)
            _buildNavItem(
              NavigationItem(
                icon: Icons.logout,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 16 : 12,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 22,
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school,
                        size: 28,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'EduPulse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.navigationItems[index];
                    final isSelected = index == widget.selectedIndex;
                    return ListTile(
                      leading: Icon(item.icon, color: Colors.white),
                      title: Text(item.label, style: const TextStyle(color: Colors.white)),
                      selected: isSelected,
                      selectedTileColor: Colors.white.withValues(alpha: 0.15),
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
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text('Logout', style: TextStyle(color: Colors.white70)),
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
