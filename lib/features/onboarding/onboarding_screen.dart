import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  OnboardingScreen — Premium feature showcase with Skip
//  Shows 5 slides about ASTRACK features, can skip to Login anytime
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  late AnimationController _animCtrl;

  final List<_OnboardSlide> _slides = [
    _OnboardSlide(
      imageUrl: 'https://images.unsplash.com/photo-1579621970588-a35d0e7ab9b6?auto=format&fit=crop&q=80&w=600',
      colorHex: 0xFF1DB954,
      title: 'Kendalikan Keuangan Anda',
      subtitle: 'Dashboard finansial lengkap',
      description:
          'Pantau pemasukan, pengeluaran, tabungan, dan saldo seluruh sumber dana dalam satu tampilan cerdas yang menyenangkan.',
      features: ['Saldo real-time', 'Multi rekening', 'Ringkasan bulanan'],
    ),
    _OnboardSlide(
      imageUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&q=80&w=600',
      colorHex: 0xFF0EA5E9,
      title: 'Catat Transaksi Instan',
      subtitle: 'Berbagai cara input',
      description:
          'Tambah transaksi lewat teks natural, perintah suara, atau scan struk fisik. Tercatat otomatis, rapi, dan akurat.',
      features: ['Input suara', 'Scan struk (OCR)', 'Teks natural AI'],
    ),
    _OnboardSlide(
      imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?auto=format&fit=crop&q=80&w=600',
      colorHex: 0xFF8B5CF6,
      title: 'Asisten AI Finansial',
      subtitle: 'Bicara, lalu tercatat',
      description:
          'Cukup ceritakan: "Tadi beli kopi 15rb pakai uang jajan". AI langsung menyusunnya menjadi transaksi yang rapi.',
      features: ['Pemahaman konteks', 'Kategori otomatis', 'Konfirmasi dulu'],
    ),
    _OnboardSlide(
      imageUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&q=80&w=600',
      colorHex: 0xFFF59E0B,
      title: 'Spreadsheet Interaktif',
      subtitle: 'Seperti Excel, tapi lebih cerdas',
      description:
          'Lihat, edit, dan analisis data keuangan dalam format spreadsheet lengkap — Keuangan, Pemasukan, Pengeluaran, Tabungan, Anggaran.',
      features: ['8 sheet terintegrasi', 'Rumus otomatis', 'Filter & sort'],
    ),
    _OnboardSlide(
      imageUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&q=80&w=600',
      colorHex: 0xFFEC4899,
      title: 'Laporan & Analisis',
      subtitle: 'Data jadi keputusan',
      description:
          'Grafik tren, pie chart kategori, laporan bulanan & tahunan. Pahami pola belanja Anda dan buat keputusan finansial yang lebih bijak.',
      features: ['Grafik interaktif', 'Export laporan', 'Insight otomatis'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? AppColors.darkDeepBg : const Color(0xFFF5FAF7);
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final slide = _slides[_currentPage];
    final slideColor = Color(slide.colorHex);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ASTRACK wordmark
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            slideColor,
                            slideColor.withAlpha(200),
                          ]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.track_changes_rounded,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ASTRACK',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),

                  // Skip button
                  TextButton(
                    onPressed: _goToLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lewati', style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── PageView ──────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  return _buildSlidePage(
                    slide: _slides[index],
                    isDark: isDark,
                    cardColor: cardColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isCurrent: index == _currentPage,
                  );
                },
              ),
            ),

            // ── Bottom bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  // Page dots
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Color(_slides[_currentPage].colorHex)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const Spacer(),

                  // Next / Mulai button
                  GestureDetector(
                    onTap: _next,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Color(_slides[_currentPage].colorHex),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Color(_slides[_currentPage].colorHex).withAlpha(70),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _slides.length - 1 ? 'Mulai Sekarang' : 'Selanjutnya',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                        ],
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

  Widget _buildSlidePage({
    required _OnboardSlide slide,
    required bool isDark,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isCurrent,
  }) {
    final slideColor = Color(slide.colorHex);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // ── Hero illustration ──────────────────────────────────────────
          Expanded(
            flex: 4,
            child: AnimatedScale(
              scale: isCurrent ? 1.0 : 0.92,
              duration: const Duration(milliseconds: 350),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: slideColor.withAlpha(isDark ? 30 : 20),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: slideColor.withAlpha(60), width: 1.5),
                ),
                child: Column(
                  children: [
                    // Big Image
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                        child: Image.network(
                          slide.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Center(child: CircularProgressIndicator(color: slideColor));
                          },
                          errorBuilder: (ctx, _, __) => Icon(Icons.image_not_supported_rounded, color: slideColor, size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Feature chips
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: slide.features.map((f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: slideColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: slideColor.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: slideColor, size: 14),
                              const SizedBox(width: 5),
                              Text(f,
                                  style: TextStyle(
                                    color: slideColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Text content ───────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.subtitle.toUpperCase(),
                    style: TextStyle(
                      color: slideColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slide.title,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slide.description,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardSlide {
  final String imageUrl;
  final int colorHex;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;

  const _OnboardSlide({
    required this.imageUrl,
    required this.colorHex,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
  });
}
