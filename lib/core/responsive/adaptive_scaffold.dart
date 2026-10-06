import 'package:flutter/material.dart';
import '../../core/responsive/responsive_breakpoints.dart';
import '../../core/theme/astrack_theme_extension.dart';
import '../../widgets/modern_bottom_nav.dart';

/// Destination item for adaptive navigation
class AdaptiveNavDestination {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;

  const AdaptiveNavDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}

/// Adaptive Scaffold supporting BottomNav on Compact (<600) and NavigationRail on Medium/Expanded (>=600)
class AdaptiveNavigationScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationIndexChanged;
  final VoidCallback onQuickAddPressed;
  final List<AdaptiveNavDestination> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AdaptiveNavigationScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationIndexChanged,
    required this.onQuickAddPressed,
    required this.destinations,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = context.isTabletOrLarger;
    final theme = context.astrackTheme;
    final isDark = theme.isDark;

    if (!isTabletOrLarger) {
      // Phone layout with ModernBottomNav
      return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: ModernBottomNav(
          currentIndex: currentIndex,
          onTabSelected: onNavigationIndexChanged,
          onCenterFabPressed: onQuickAddPressed,
          isDark: isDark,
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // Tablet / iPad / Desktop layout with NavigationRail
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onNavigationIndexChanged,
            backgroundColor: theme.surface,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: FloatingActionButton.small(
                elevation: 2,
                backgroundColor: theme.primaryEmerald,
                foregroundColor: Colors.white,
                onPressed: onQuickAddPressed,
                child: const Icon(Icons.add_rounded, size: 24),
              ),
            ),
            selectedIconTheme: IconThemeData(color: theme.primaryEmerald, size: 26),
            unselectedIconTheme: IconThemeData(color: theme.textSecondary, size: 24),
            selectedLabelTextStyle: TextStyle(
              color: theme.primaryEmerald,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: theme.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon ?? d.icon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: theme.border,
          ),
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}
