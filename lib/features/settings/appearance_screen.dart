import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/personalization_models.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_motion.dart';
import '../../core/responsive/responsive_breakpoints.dart';
import '../../core/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import 'widgets/live_preview_card.dart';
import 'widgets/review_appearance_sheet.dart';

/// Screen allowing users to customize Theme, Accent Color, Text Size, and UI Style
/// with Staged Changes, Atomic Review/Apply, and Real-Time Live Preview.
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  @override
  void initState() {
    super.initState();
    // Start staging session so changes don't overwrite app state prematurely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ThemeProvider>().startStaging();
      }
    });
  }

  Future<bool> _onWillPop(ThemeProvider theme) async {
    if (!theme.hasUnsavedChanges) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.isDarkMode ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buang Perubahan?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Anda memiliki perubahan tampilan yang belum diterapkan. Buang perubahan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              theme.discardStaged();
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Buang'),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  void _openReviewSheet(BuildContext context, ThemeProvider theme) {
    ReviewAppearanceSheet.show(
      context,
      diffs: theme.pendingDiffs,
      onDiscard: () {
        theme.discardStaged();
        theme.startStaging();
      },
      onApply: () async {
        await theme.applyStaged();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(context).changesApplied),
                ],
              ),
              backgroundColor: theme.accentColor.getColor(theme.isDarkMode),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          // Restart a clean staging session matching the newly applied active settings
          theme.startStaging();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final staged = theme.currentSettings;
    final isDark = theme.isDarkMode;
    final isTablet = context.isTabletOrLarger;
    final hasChanges = theme.hasUnsavedChanges;
    final loc = AppLocalizations.of(context);

    return PopScope(
      canPop: !hasChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(theme);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            loc.appearanceTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Main content: Adaptive Two-Pane for Tablet / Single Column for Phone
              Positioned.fill(
                child: isTablet
                    ? _buildTabletLayout(context, theme, staged, isDark, loc)
                    : _buildPhoneLayout(context, theme, staged, isDark, loc),
              ),

              // Sticky Floating Bottom Bar for Unsaved Changes
              if (hasChanges)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: _buildBottomStickyBar(context, theme, isDark, loc),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Tablet / Expanded Two-Pane Layout ---
  Widget _buildTabletLayout(
    BuildContext context,
    ThemeProvider theme,
    PersonalizationSettings staged,
    bool isDark,
    AppLocalizations loc,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pane: Controls
          Expanded(
            flex: 5,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: _buildControlSections(context, theme, staged, isDark, loc),
            ),
          ),
          const SizedBox(width: 24),

          // Right Pane: Sticky Live Preview
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader(loc.livePreviewTitle, isDark),
                  const SizedBox(height: 10),
                  LivePreviewCard(settings: staged),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Phone Single Column Layout ---
  Widget _buildPhoneLayout(
    BuildContext context,
    ThemeProvider theme,
    PersonalizationSettings staged,
    bool isDark,
    AppLocalizations loc,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: [
        // Live Preview Section
        _buildSectionHeader(loc.livePreviewTitle, isDark),
        const SizedBox(height: 10),
        LivePreviewCard(settings: staged),
        const SizedBox(height: 24),

        // Controls
        ..._buildControlSections(context, theme, staged, isDark, loc),
      ],
    );
  }

  // --- Shared Control Sections ---
  List<Widget> _buildControlSections(
    BuildContext context,
    ThemeProvider theme,
    PersonalizationSettings staged,
    bool isDark,
    AppLocalizations loc,
  ) {
    return [
      // 1. Theme Mode
      _buildSectionHeader(loc.themeSection, isDark),
      const SizedBox(height: 8),
      _buildThemeSelector(theme, staged, isDark, loc),
      const SizedBox(height: 24),

      // 2. Accent Color
      _buildSectionHeader(loc.accentSection, isDark),
      const SizedBox(height: 4),
      Text(
        loc.accentDesc,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
        ),
      ),
      const SizedBox(height: 10),
      _buildAccentColorPicker(theme, staged, isDark),
      const SizedBox(height: 24),

      // 3. Text Size
      _buildSectionHeader(loc.textSizeSection, isDark),
      const SizedBox(height: 4),
      Text(
        loc.textSizeDesc,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
        ),
      ),
      const SizedBox(height: 10),
      _buildTextSizeSelector(theme, staged, isDark),
      const SizedBox(height: 24),

      // 4. UI Style
      _buildSectionHeader(loc.uiStyleSection, isDark),
      const SizedBox(height: 4),
      Text(
        loc.uiStyleDesc,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
        ),
      ),
      const SizedBox(height: 10),
      _buildUiStyleSelector(theme, staged, isDark),
    ];
  }

  // --- Theme Mode Selector ---
  Widget _buildThemeSelector(
    ThemeProvider theme,
    PersonalizationSettings staged,
    bool isDark,
    AppLocalizations loc,
  ) {
    final modes = [
      (ThemeMode.system, loc.themeSystem, Icons.brightness_auto_rounded, loc.themeSystemDesc),
      (ThemeMode.light, loc.themeLight, Icons.light_mode_rounded, loc.themeLightDesc),
      (ThemeMode.dark, loc.themeDark, Icons.dark_mode_rounded, loc.themeDarkDesc),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: modes.map((m) {
          final isSelected = staged.themeMode == m.$1;
          final accentColor = staged.accentColor.getColor(isDark);

          return Column(
            children: [
              InkWell(
                onTap: () {
                  theme.updateStaged(staged.copyWith(themeMode: m.$1));
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor.withOpacity(0.12) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          m.$3,
                          size: 20,
                          color: isSelected ? accentColor : (isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.$2,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.$4,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? accentColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 6.5 : 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (m != modes.last)
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- Accent Color Picker ---
  Widget _buildAccentColorPicker(
    ThemeProvider theme,
    PersonalizationSettings staged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - (AppSpacing.md * 2)) / 3;

          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: AppAccentColor.values.map((accent) {
              final isSelected = staged.accentColor == accent;
              final color = accent.getColor(isDark);

              return InkWell(
                onTap: () {
                  theme.updateStaged(staged.copyWith(accentColor: accent));
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: itemWidth,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.10) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Swatch Circle
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        accent.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // --- Text Size Selector ---
  Widget _buildTextSizeSelector(
    ThemeProvider theme,
    PersonalizationSettings staged,
    bool isDark,
  ) {
    final scales = AppTextScale.values;
    final accentColor = staged.accentColor.getColor(isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: scales.map((scale) {
              final isSelected = staged.textScale == scale;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      theme.updateStaged(staged.copyWith(textScale: scale));
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? accentColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aa',
                            style: TextStyle(
                              fontSize: 14 * scale.factor,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? accentColor : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scale.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? accentColor : (isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- UI Style Selector ---
  Widget _buildUiStyleSelector(
    ThemeProvider theme,
    PersonalizationSettings staged,
    bool isDark,
  ) {
    final styles = AppUiStyle.values;
    final accentColor = staged.accentColor.getColor(isDark);

    return Column(
      children: styles.map((style) {
        final isSelected = staged.uiStyle == style;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () {
              theme.updateStaged(staged.copyWith(uiStyle: style));
            },
            borderRadius: style.cardBorderRadius,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: style.cardBorderRadius,
                border: Border.all(
                  color: isSelected ? accentColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 2.0 : style.borderWidth,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: style.cardElevation * 2,
                          offset: Offset(0, style.cardElevation),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Shape preview token thumbnail
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withOpacity(0.12) : (isDark ? const Color(0xFF141C18) : const Color(0xFFF1F5F9)),
                      borderRadius: style.buttonBorderRadius,
                      border: Border.all(
                        color: isSelected ? accentColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: style.borderWidth,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.widgets_outlined,
                        size: 20,
                        color: isSelected ? accentColor : (isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              style.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            if (style == AppUiStyle.soft) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'DEFAULT',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: accentColor),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          style.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? accentColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 6.5 : 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Sticky Floating Bottom Bar for Staged Changes ---
  Widget _buildBottomStickyBar(
    BuildContext context,
    ThemeProvider theme,
    bool isDark,
    AppLocalizations loc,
  ) {
    final count = theme.changeCount;
    final accentColor = theme.currentSettings.accentColor.getColor(isDark);
    final isReduceMotion = AppMotion.isReduceMotion(context);

    return AnimatedSlide(
      offset: Offset.zero,
      duration: isReduceMotion ? Duration.zero : AppMotion.fast,
      curve: AppMotion.enterCurve,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141C18) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Dynamic count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    loc.changesCount(count),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Discard Button
            TextButton(
              onPressed: () {
                theme.discardStaged();
                theme.startStaging();
              },
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: Text(
                loc.cancel,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),

            // Review Button
            ElevatedButton(
              onPressed: () => _openReviewSheet(context, theme),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tinjau',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
