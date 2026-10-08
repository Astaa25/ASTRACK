import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import 'setup_sources_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  UserCustomizationScreen
//  Asks user for preferences before entering the app for the first time.
//  Goes to SetupSourcesScreen after completing.
// ─────────────────────────────────────────────────────────────────────────────
class UserCustomizationScreen extends StatefulWidget {
  final String userName;

  const UserCustomizationScreen({super.key, required this.userName});

  @override
  State<UserCustomizationScreen> createState() => _UserCustomizationScreenState();
}

class _UserCustomizationScreenState extends State<UserCustomizationScreen>
    with SingleTickerProviderStateMixin {
  // Step
  int _step = 0; // 0=currency, 1=profile pic, 2=notification, 3=summary
  bool _isLoading = false;

  // Choices
  String _currency = 'IDR';
  bool _notifBudget = true;
  bool _notifWeekly = true;
  String _avatar = '💰';

  late AnimationController _anim;
  late Animation<double> _fade;

  final List<Map<String, String>> _currencies = [
    {'code': 'IDR', 'name': 'Rupiah Indonesia', 'symbol': 'Rp', 'flag': '🇮🇩'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$', 'flag': '🇸🇬'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM', 'flag': '🇲🇾'},
  ];


  final List<String> _avatars = [
    '💰', '🎯', '📊', '🌱', '⭐', '🚀', '💎', '🏆', '🌸', '🔥',
  ];

  final int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      _anim.reset();
      setState(() => _step++);
      _anim.forward();
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_step > 0) {
      _anim.reset();
      setState(() => _step--);
      _anim.forward();
    }
  }

  void _finish() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SetupSourcesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bgColor = isDark ? AppColors.darkDeepBg : const Color(0xFFF5FAF7);
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Halo, ${widget.userName.split(' ').first} 👋',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_step + 1}/$_totalSteps',
                        style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Atur ASTRACK sesuai kebutuhan Anda sebelum mulai.',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _totalSteps,
                      minHeight: 5,
                      backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      valueColor: AlwaysStoppedAnimation(primary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: _buildStep(
                    isDark: isDark, primary: primary, cardColor: cardColor,
                    textPrimary: textPrimary, textSecondary: textSecondary,
                  ),
                ),
              ),
            ),

            // ── Navigation bar ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _prev,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(
                              _step == _totalSteps - 1 ? 'Mulai Setup Sumber Dana →' : 'Lanjutkan',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required bool isDark,
    required Color primary,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    switch (_step) {
      case 0:
        return _stepCurrency(isDark, primary, cardColor, textPrimary, textSecondary);
      case 1:
        return _stepAvatar(isDark, primary, cardColor, textPrimary, textSecondary);
      case 2:
        return _stepNotifications(isDark, primary, cardColor, textPrimary, textSecondary);
      case 3:
        return _stepSummary(isDark, primary, cardColor, textPrimary, textSecondary);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Currency ───────────────────────────────────────────────────────
  Widget _stepCurrency(bool isDark, Color primary, Color cardColor, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          icon: Icons.currency_exchange_rounded,
          color: primary,
          title: 'Mata Uang Utama',
          subtitle: 'Pilih mata uang yang ingin Anda gunakan di ASTRACK.',
        ),
        const SizedBox(height: 16),
        ...(_currencies.map((c) {
          final isSelected = _currency == c['code'];
          return GestureDetector(
            onTap: () => setState(() { _currency = c['code']!; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? primary.withAlpha(15) : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name']!,
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${c['code']} · ${c['symbol']}',
                            style: TextStyle(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: primary, size: 22),
                ],
              ),
            ),
          );
        })),
      ],
    );
  }


  // ── Step 2: Avatar ─────────────────────────────────────────────────────────
  Widget _stepAvatar(bool isDark, Color primary, Color cardColor, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          icon: Icons.face_rounded,
          color: primary,
          title: 'Pilih Avatar',
          subtitle: 'Pilih emoji yang mewakili Anda di ASTRACK.',
        ),
        const SizedBox(height: 20),

        // Current avatar preview
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: primary.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: primary, width: 3),
            ),
            child: Center(
              child: Text(_avatar, style: const TextStyle(fontSize: 48)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(widget.userName.split(' ').first,
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        ),

        const SizedBox(height: 24),

        Text('Pilih Avatar:', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: _avatars.map((emoji) {
            final isSelected = _avatar == emoji;
            return GestureDetector(
              onTap: () => setState(() => _avatar = emoji),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? primary.withAlpha(20) : cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 3: Notifications ──────────────────────────────────────────────────
  Widget _stepNotifications(bool isDark, Color primary, Color cardColor, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          icon: Icons.notifications_active_rounded,
          color: primary,
          title: 'Pengaturan Notifikasi',
          subtitle: 'Pilih notifikasi yang ingin Anda terima dari ASTRACK.',
        ),
        const SizedBox(height: 16),

        _notifTile(
          cardColor: cardColor,
          isDark: isDark,
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF59E0B),
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Peringatan Anggaran',
          subtitle: 'Notifikasi saat 70%, 90%, dan 100% anggaran terpakai.',
          value: _notifBudget,
          onChanged: (v) => setState(() => _notifBudget = v),
        ),

        const SizedBox(height: 10),

        _notifTile(
          cardColor: cardColor,
          isDark: isDark,
          icon: Icons.calendar_today_rounded,
          iconColor: const Color(0xFF0EA5E9),
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Laporan Mingguan',
          subtitle: 'Ringkasan pengeluaran dan tabungan setiap minggu.',
          value: _notifWeekly,
          onChanged: (v) => setState(() => _notifWeekly = v),
        ),
      ],
    );
  }

  // ── Step 4: Summary ────────────────────────────────────────────────────────
  Widget _stepSummary(bool isDark, Color primary, Color cardColor, Color textPrimary, Color textSecondary) {
    final currencyData = _currencies.firstWhere((c) => c['code'] == _currency, orElse: () => _currencies.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          icon: Icons.check_circle_rounded,
          color: primary,
          title: 'Ringkasan Pengaturan',
          subtitle: 'Konfirmasi pilihan Anda sebelum mulai menggunakan ASTRACK.',
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _summaryTile(
                icon: _avatar, label: 'Avatar', value: widget.userName,
                textPrimary: textPrimary, textSecondary: textSecondary,
              ),
              _summaryDivider(isDark),
              _summaryTile(
                icon: currencyData['flag']!,
                label: 'Mata Uang',
                value: '${currencyData['name']} (${currencyData['code']})',
                textPrimary: textPrimary, textSecondary: textSecondary,
              ),
              _summaryDivider(isDark),
              _summaryTileWidget(
                icon: '🔔',
                label: 'Notifikasi',
                value: [
                  if (_notifBudget) 'Anggaran',
                  if (_notifWeekly) 'Mingguan',
                  if (!_notifBudget && !_notifWeekly) 'Nonaktif',
                ].join(', '),
                textPrimary: textPrimary, textSecondary: textSecondary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primary.withAlpha(15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withAlpha(50)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Selanjutnya Anda akan mengatur sumber dana seperti rekening bank, dompet, dll.',
                  style: TextStyle(color: primary, fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────
  Widget _sectionHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }


  Widget _notifTile({
    required Color cardColor,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color textPrimary,
    required Color textSecondary,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.lightPrimary,
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTileWidget({
    required String icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _summaryDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}
