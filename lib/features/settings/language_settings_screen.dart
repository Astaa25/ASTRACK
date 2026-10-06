import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/tokens/app_motion.dart';
import '../../app/theme/app_colors.dart';

/// Screen allowing users to select and stage the active App Language (ID / EN)
/// with consistent interaction pattern, atomic apply, and scalable architecture.
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  Locale? _stagedLocale;

  @override
  void initState() {
    super.initState();
    final theme = context.read<ThemeProvider>();
    _stagedLocale = theme.locale;
  }

  bool get _hasChanges {
    final active = context.read<ThemeProvider>().locale;
    return _stagedLocale != null && _stagedLocale!.languageCode != active.languageCode;
  }

  void _applyLanguage(BuildContext context, ThemeProvider theme) async {
    if (_stagedLocale == null) return;
    await theme.setLocale(_stagedLocale!);

    if (context.mounted) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(loc.languageUpdated),
            ],
          ),
          backgroundColor: theme.accentColor.getColor(theme.isDarkMode),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;
    final accentColor = theme.accentColor.getColor(isDark);
    final loc = AppLocalizations.of(context);
    final hasChanges = _hasChanges;

    final languages = [
      (
        const Locale('id', 'ID'),
        'Bahasa Indonesia',
        'Indonesia (ID)',
        'Bahasa bawaan dengan format Rupiah standar',
        '🇮🇩',
      ),
      (
        const Locale('en', 'US'),
        'English',
        'United States (US)',
        'English interface with financial metrics',
        '🇺🇸',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.languageTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _buildSectionHeader('PILIH BAHASA / SELECT LANGUAGE', isDark),
                const SizedBox(height: 6),
                Text(
                  loc.languageSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: languages.map((lang) {
                      final isSelected = _stagedLocale?.languageCode == lang.$1.languageCode;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _stagedLocale = lang.$1;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  // Flag Icon / Emoji
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accentColor.withOpacity(0.12)
                                          : (isDark ? const Color(0xFF141C18) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        lang.$5,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 2,
                                          children: [
                                            Text(
                                              lang.$2,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                            Text(
                                              '(${lang.$3})',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          lang.$4,
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
                          if (lang != languages.last)
                            Divider(
                              height: 1,
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            // Sticky Bottom Bar for Language Changes
            if (hasChanges)
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: AnimatedSlide(
                  offset: Offset.zero,
                  duration: AppMotion.getDuration(context, AppMotion.fast),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.language_rounded, size: 16, color: accentColor),
                              const SizedBox(width: 6),
                              Text(
                                loc.changesCount(1),
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

                        TextButton(
                          onPressed: () {
                            setState(() {
                              _stagedLocale = theme.locale;
                            });
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

                        ElevatedButton(
                          onPressed: () => _applyLanguage(context, theme),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            loc.applyChanges,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
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
