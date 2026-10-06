import 'package:flutter/material.dart';
import '../../../core/theme/personalization_models.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/fund_chip.dart';
import '../../../shared/widgets/progress_bar.dart';

/// Live Preview Widget displaying real ASTRACK components that update in real time
/// as the user tweaks Theme, Accent Color, Text Scale, and UI Style.
class LivePreviewCard extends StatefulWidget {
  final PersonalizationSettings settings;

  const LivePreviewCard({
    super.key,
    required this.settings,
  });

  @override
  State<LivePreviewCard> createState() => _LivePreviewCardState();
}

class _LivePreviewCardState extends State<LivePreviewCard> {
  bool _isBalanceHidden = false;

  bool _computeIsDark(BuildContext context) {
    if (widget.settings.themeMode == ThemeMode.dark) return true;
    if (widget.settings.themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _computeIsDark(context);
    final accent = widget.settings.accentColor;
    final uiStyle = widget.settings.uiStyle;
    final textScale = widget.settings.textScale;

    final previewTheme = isDark
        ? AppTheme.buildDarkTheme(accent: accent, uiStyle: uiStyle)
        : AppTheme.buildLightTheme(accent: accent, uiStyle: uiStyle);

    final accentColor = accent.getColor(isDark);
    final cardBorder = BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      width: uiStyle.borderWidth,
    );

    return Theme(
      data: previewTheme,
      child: Builder(
        builder: (ctx) {
          final parentQuery = MediaQuery.of(ctx);
          final previewScaler = TextScaler.linear(textScale.factor);

          return MediaQuery(
            data: parentQuery.copyWith(textScaler: previewScaler),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF090D0B) : const Color(0xFFF8FAFC),
                borderRadius: uiStyle.cardBorderRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.0,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: uiStyle.cardBorderRadius,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preview Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111815) : Colors.white,
                        border: Border(bottom: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'LIVE PREVIEW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge: UI Style
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.12),
                                borderRadius: uiStyle.chipBorderRadius,
                              ),
                              child: Text(
                                '${uiStyle.name} · ${accent.name}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Inner Component Showcase
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Mini Balance Card
                          _buildBalanceCard(isDark, accentColor, uiStyle),
                          const SizedBox(height: 14),

                          // 2. Fund Chips Row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FundChip(
                                  title: 'Dompet Utama',
                                  balance: 12450000,
                                  isSelected: true,
                                  onTap: () {},
                                ),
                                const SizedBox(width: 8),
                                FundChip(
                                  title: 'Tabungan',
                                  balance: 2400000,
                                  isSelected: false,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. Real Transaction Row
                          _buildTransactionTile(isDark, uiStyle),
                          const SizedBox(height: 14),

                          // 4. Progress / Budget Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Anggaran Bulanan (65%)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rp3.25jt / Rp5jt',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const ProgressBar(
                                progress: 0.65,
                                height: 7,
                                enableSemanticColors: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 5. Primary Action Button
                          PrimaryButton(
                            label: 'Catat Pengeluaran',
                            icon: Icons.add_rounded,
                            height: 46,
                            onPressed: () {},
                          ),
                          const SizedBox(height: 14),

                          // 6. Navigation Preview Strip
                          _buildMiniNavBar(isDark, accentColor, uiStyle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(bool isDark, Color accentColor, AppUiStyle uiStyle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111815) : Colors.white,
        borderRadius: uiStyle.cardBorderRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: uiStyle.borderWidth,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Saldo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                child: Icon(
                  _isBalanceHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isBalanceHidden ? 'Rp ••••••••' : 'Rp 14.850.000',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Income
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.incomeDark : AppColors.income).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        size: 13,
                        color: isDark ? AppColors.incomeDark : AppColors.income,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pemasukan',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '+Rp8.500.000',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.incomeDark : AppColors.income,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
                width: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              const SizedBox(width: 8),
              // Expense
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.expenseDark : AppColors.expense).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 13,
                        color: isDark ? AppColors.expenseDark : AppColors.expense,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengeluaran',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '-Rp3.200.000',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.expenseDark : AppColors.expense,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(bool isDark, AppUiStyle uiStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111815) : Colors.white,
        borderRadius: uiStyle.cardBorderRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: uiStyle.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.expenseDark : AppColors.expense).withOpacity(0.12),
              borderRadius: uiStyle.buttonBorderRadius,
            ),
            child: Icon(
              Icons.coffee_rounded,
              size: 20,
              color: isDark ? AppColors.expenseDark : AppColors.expense,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kopi Kenangan Mantan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Makanan & Minuman • BCA',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-Rp28.000',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.expenseDark : AppColors.expense,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Hari ini, 14:20',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniNavBar(bool isDark, Color accentColor, AppUiStyle uiStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C18) : Colors.white,
        borderRadius: uiStyle.cardBorderRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: uiStyle.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildNavItem(Icons.dashboard_rounded, 'Beranda', true, accentColor, isDark)),
          Expanded(child: _buildNavItem(Icons.receipt_long_rounded, 'Transaksi', false, accentColor, isDark)),
          Expanded(child: _buildNavItem(Icons.pie_chart_rounded, 'Anggaran', false, accentColor, isDark)),
          Expanded(child: _buildNavItem(Icons.settings_rounded, 'Pengaturan', false, accentColor, isDark)),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, Color accentColor, bool isDark) {
    final color = isActive
        ? accentColor
        : (isDark ? AppColors.darkMuted : AppColors.lightTextSecondary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (isActive) ...[
          const SizedBox(height: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}
