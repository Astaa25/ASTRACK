import 'package:flutter/material.dart';
import '../../../core/theme/personalization_models.dart';
import '../../../core/theme/astrack_theme_extension.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

/// Modal Bottom Sheet displaying all staged appearance changes
/// with atomic Discard and Apply actions.
class ReviewAppearanceSheet extends StatelessWidget {
  final List<SettingDiffItem> diffs;
  final VoidCallback onDiscard;
  final VoidCallback onApply;

  const ReviewAppearanceSheet({
    super.key,
    required this.diffs,
    required this.onDiscard,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required List<SettingDiffItem> diffs,
    required VoidCallback onDiscard,
    required VoidCallback onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewAppearanceSheet(
        diffs: diffs,
        onDiscard: onDiscard,
        onApply: onApply,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.astrackTheme;
    final isDark = theme.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  color: theme.primaryAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tinjau Perubahan Tampilan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Perubahan akan diterapkan secara menyeluruh',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Diffs List
          if (diffs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Tidak ada perubahan yang tertunda.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: diffs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = diffs[index];
                  return _buildDiffTile(context, item, isDark, theme);
                },
              ),
            ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Buang',
                  icon: Icons.delete_outline_rounded,
                  isDestructive: true,
                  height: 48,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDiscard();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Terapkan Perubahan',
                  icon: Icons.check_circle_outline_rounded,
                  height: 48,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onApply();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiffTile(
    BuildContext context,
    SettingDiffItem item,
    bool isDark,
    AstrackThemeExtension theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C18) : theme.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: theme.primaryAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.oldValue,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: theme.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    if (item.colorPreview != null) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item.colorPreview,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      item.newValue,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
