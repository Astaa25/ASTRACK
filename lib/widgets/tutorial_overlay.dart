import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppTutorialOverlay — First-launch feature walkthrough
//  Usage: Wrap widgets in TutorialTarget, then call AppTutorialController.show()
// ─────────────────────────────────────────────────────────────────────────────

// Individual tutorial step definition
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double? arrowAlignment;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.arrowAlignment,
  });
}

// Main overlay widget — shows a series of tutorial cards
class AppTutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onFinished;

  const AppTutorialOverlay({
    super.key,
    required this.steps,
    required this.onFinished,
  });

  @override
  State<AppTutorialOverlay> createState() => _AppTutorialOverlayState();
}

class _AppTutorialOverlayState extends State<AppTutorialOverlay>
    with TickerProviderStateMixin {
  int _current = 0;
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < widget.steps.length - 1) {
      _anim.reset();
      setState(() => _current++);
      _anim.forward();
    } else {
      widget.onFinished();
    }
  }

  void _prev() {
    if (_current > 0) {
      _anim.reset();
      setState(() => _current--);
      _anim.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_current];
    final isLast = _current == widget.steps.length - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _next,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.black.withAlpha(160),
        child: SafeArea(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: TextButton(
                  onPressed: widget.onFinished,
                  child: const Text('Lewati Tutorial',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              ),
            ),

            const Spacer(),

            // Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: step.color.withAlpha(60),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon + step counter
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: step.color.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(step.icon, color: step.color, size: 26),
                            ),
                            const Spacer(),
                            Text(
                              '${_current + 1} / ${widget.steps.length}',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Text(
                          step.title,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.description,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Progress dots and Navigation
                        Row(
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(widget.steps.length, (i) {
                                    final isActive = i == _current;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.only(right: 5),
                                      width: isActive ? 18 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? step.color
                                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Navigation
                            if (_current > 0) ...[
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                onPressed: _prev,
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  size: 20,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            GestureDetector(
                              onTap: _next,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: step.color,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isLast ? 'Selesai! 🎉' : 'Lanjut',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (!isLast) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white, size: 14),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Dashboard tutorial steps
// ─────────────────────────────────────────────────────────────────────────────
const List<TutorialStep> kDashboardTutorialSteps = [
  TutorialStep(
    icon: Icons.dashboard_rounded,
    color: Color(0xFF16A34A),
    title: 'Selamat Datang di ASTRACK! 🎉',
    description:
        'ASTRACK adalah asisten keuangan pribadi Anda. Dashboard ini menampilkan ringkasan lengkap kondisi finansial Anda setiap saat.',
  ),
  TutorialStep(
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF0EA5E9),
    title: 'Total Saldo & Ringkasan',
    description:
        'Lihat total saldo semua rekening, pemasukan bulan ini, pengeluaran, dan tabungan Anda dalam satu pandangan.',
  ),
  TutorialStep(
    icon: Icons.add_circle_rounded,
    color: Color(0xFF8B5CF6),
    title: 'Tambah Transaksi',
    description:
        'Klik tombol "+" di bawah untuk menambahkan transaksi. Pilih dari input manual, suara, teks natural, atau scan struk.',
    arrowAlignment: 0.0, // Center FAB
  ),
  TutorialStep(
    icon: Icons.table_chart_rounded,
    color: Color(0xFFF59E0B),
    title: 'Daftar Transaksi',
    description:
        'Buka tab Keuangan untuk memantau semua riwayat transaksi yang masuk maupun keluar secara rinci.',
    arrowAlignment: -0.4, 
  ),
  TutorialStep(
    icon: Icons.smart_toy_rounded,
    color: Color(0xFFEC4899),
    title: 'AI Financial Assistant',
    description:
        'Gunakan asisten AI saat menambah transaksi. Cukup ceritakan dalam bahasa sehari-hari, AI akan memprosesnya secara otomatis.',
    arrowAlignment: 0.0,
  ),
  TutorialStep(
    icon: Icons.bar_chart_rounded,
    color: Color(0xFF6366F1),
    title: 'Statistik & Analisis',
    description:
        'Buka tab Statistik untuk melihat grafik tren pengeluaran, pie chart kategori, dan ringkasan kondisi finansial Anda.',
    arrowAlignment: 0.4,
  ),
  TutorialStep(
    icon: Icons.menu_rounded,
    color: Color(0xFFF43F5E),
    title: 'Fitur Lainnya',
    description:
        'Buka tab Lainnya untuk mengatur Tagihan Rutin, Anggaran Bulanan, Target Tabungan, dan Export Data.',
    arrowAlignment: 0.8,
  ),
];
