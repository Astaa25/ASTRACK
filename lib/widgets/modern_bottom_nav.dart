import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme/app_colors.dart';

/// Ultra-smooth Liquid Glass Bottom Navigation Bar for ASTRACK.
///
/// Features:
/// - Real Frosted Glassmorphism with BackdropFilter blur & specular rim highlight
/// - Fluid morphing sliding indicator pill that glides with spring curves
/// - Haptic feedback on tap
/// - Subtle icon scale bounce and color transition micro-interactions
/// - Glowing Center Action Button with liquid gradient and press scale
class ModernBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onCenterFabPressed;
  final bool isDark;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCenterFabPressed,
    required this.isDark,
  });

  @override
  State<ModernBottomNav> createState() => _ModernBottomNavState();
}

class _ModernBottomNavState extends State<ModernBottomNav> {
  double _centerFabScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inactiveColor = isDark ? AppColors.darkMuted : AppColors.lightTextSecondary;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? const Color(0xEE161B26)
                        : Colors.white.withOpacity(0.88),
                    isDark
                        ? const Color(0xD91E293B)
                        : Colors.white.withOpacity(0.76),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.14)
                      : Colors.white.withOpacity(0.65),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.38 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  if (isDark)
                    BoxShadow(
                      color: activeColor.withOpacity(0.08),
                      blurRadius: 28,
                      spreadRadius: -2,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final slotWidth = totalWidth / 5;

                  // Map currentIndex (0: Home, 1: Keuangan, 2: Statistik, 3: Lainnya) to 5 visual slots:
                  // Slot 0: Home
                  // Slot 1: Keuangan
                  // Slot 2: Center FAB
                  // Slot 3: Statistik
                  // Slot 4: Lainnya
                  final activeSlot = widget.currentIndex == 0
                      ? 0
                      : (widget.currentIndex == 1
                          ? 1
                          : (widget.currentIndex == 2 ? 3 : 4));

                  final indicatorLeft = activeSlot * slotWidth;

                  return Stack(
                    children: [
                      // ─── Liquid Sliding Pill Indicator ───
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutQuart,
                        left: indicatorLeft + 4,
                        top: 5,
                        width: slotWidth - 8,
                        bottom: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                activeColor.withOpacity(isDark ? 0.22 : 0.15),
                                activeColor.withOpacity(isDark ? 0.07 : 0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: activeColor.withOpacity(isDark ? 0.32 : 0.24),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withOpacity(isDark ? 0.16 : 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 16,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: activeColor,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withOpacity(0.6),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ─── 5 Navigation Slots ───
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 0: Home
                          Expanded(
                            child: _buildNavItem(
                              index: 0,
                              label: 'Home',
                              icon: Icons.grid_view_outlined,
                              activeIcon: Icons.grid_view_rounded,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor,
                            ),
                          ),

                          // 1: Keuangan
                          Expanded(
                            child: _buildNavItem(
                              index: 1,
                              label: 'Keuangan',
                              icon: Icons.table_chart_outlined,
                              activeIcon: Icons.table_chart_rounded,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor,
                            ),
                          ),

                          // 2: Center Quick Action Button ("+")
                          SizedBox(
                            width: slotWidth,
                            child: Center(
                              child: _buildCenterFab(activeColor, isDark),
                            ),
                          ),

                          // 3: Statistik
                          Expanded(
                            child: _buildNavItem(
                              index: 2,
                              label: 'Statistik',
                              icon: Icons.pie_chart_outline_rounded,
                              activeIcon: Icons.pie_chart_rounded,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor,
                            ),
                          ),

                          // 4: Lainnya
                          Expanded(
                            child: _buildNavItem(
                              index: 3,
                              label: 'Lainnya',
                              icon: Icons.menu_rounded,
                              activeIcon: Icons.menu_open_rounded,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = widget.currentIndex == index;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTabSelected(index);
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.14 : 1.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.2,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFab(Color activeColor, bool isDark) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _centerFabScale = 0.90),
      onTapUp: (_) {
        setState(() => _centerFabScale = 1.0);
        HapticFeedback.mediumImpact();
        widget.onCenterFabPressed();
      },
      onTapCancel: () => setState(() => _centerFabScale = 1.0),
      child: AnimatedScale(
        scale: _centerFabScale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeInOut,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF10B981),
                Color(0xFF047857),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.40),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.42),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
