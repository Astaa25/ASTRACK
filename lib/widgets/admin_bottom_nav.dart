import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onCenterFabPressed;
  final bool isDark;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCenterFabPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildNavItem(
                  index: 0,
                  label: 'Dasbor',
                  icon: Icons.dashboard_rounded,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  index: 1,
                  label: 'Pengguna',
                  icon: Icons.people_alt_rounded,
                ),
              ),

              // Center Prominent "+" Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, scale, child) {
                    return GestureDetector(
                      onTapDown: (_) => {},
                      onTap: onCenterFabPressed,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                isDark ? AppColors.darkPrimary.withOpacity(0.8) : AppColors.lightPrimary.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Expanded(
                child: _buildNavItem(
                  index: 2,
                  label: 'Statistik',
                  icon: Icons.insights_rounded,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  index: 3,
                  label: 'Pengaturan',
                  icon: Icons.settings_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inactiveColor = isDark ? AppColors.darkMuted : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(16),
      splashColor: activeColor.withOpacity(0.1),
      highlightColor: activeColor.withOpacity(0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                icon,
                key: ValueKey<bool>(isSelected),
                size: isSelected ? 24 : 22,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
