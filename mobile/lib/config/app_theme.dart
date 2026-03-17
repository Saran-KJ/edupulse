import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized premium design system for EduPulse
class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF1A1F71);       // Deep indigo
  static const Color primaryLight = Color(0xFF3949AB);   // Indigo
  static const Color primarySoft = Color(0xFF5C6BC0);    // Soft indigo

  // Accent palette
  static const Color accent = Color(0xFF00BFA5);         // Teal accent
  static const Color accentLight = Color(0xFF64FFDA);    // Light teal
  static const Color accentWarm = Color(0xFFFFAB40);     // Amber accent

  // Background palette
  static const Color surface = Color(0xFFF8FAFF);        // Cool off-white
  static const Color surfaceCard = Colors.white;
  static const Color surfaceDark = Color(0xFF0D1137);    // Deep dark

  // Status colors
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFF9100);
  static const Color error = Color(0xFFFF1744);
  static const Color info = Color(0xFF2979FF);

  // Risk colors
  static const Color riskHigh = Color(0xFFFF1744);
  static const Color riskMedium = Color(0xFFFF9100);
  static const Color riskLow = Color(0xFF00C853);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Gradient colors
  static const Color gradientStart = Color(0xFF1A1F71);
  static const Color gradientMid = Color(0xFF3F37C9);
  static const Color gradientEnd = Color(0xFF7B2FF7);

  static Color getRiskColor(String? level) {
    switch (level?.toUpperCase()) {
      case 'HIGH': return riskHigh;
      case 'MEDIUM': return riskMedium;
      case 'LOW': return riskLow;
      default: return riskLow;
    }
  }
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gradientStart, AppColors.gradientMid, AppColors.gradientEnd],
  );

  static const LinearGradient primarySubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F71), Color(0xFF3949AB)],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
  );

  static const LinearGradient warmAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9100), Color(0xFFFF6D00)],
  );

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFF), Color(0xFFEEF2FF)],
  );

  static LinearGradient sidebar = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1137), Color(0xFF1A1F71), Color(0xFF1A237E)],
  );

  static LinearGradient card(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color.withValues(alpha: 0.05), color.withValues(alpha: 0.02)],
  );
}

class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> colored(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

class AppTextStyles {
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get heading => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle get statValue => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

/// Premium stat card used across dashboards
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.statValue.copyWith(fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header with decorative accent
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color ?? AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(title, style: AppTextStyles.headingSmall),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Gradient banner used for welcome headers
class GradientBanner extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final double borderRadius;

  const GradientBanner({
    super.key,
    required this.child,
    this.gradient,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.primary,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppShadows.colored(AppColors.primary),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          // Content
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: child,
          ),
        ],
      ),
    );
  }
}
