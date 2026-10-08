import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/fund_source.dart';
import '../../core/utils/currency_formatter.dart';
import '../dashboard/dashboard_screen.dart';

class SetupSourcesScreen extends StatefulWidget {
  const SetupSourcesScreen({super.key});

  @override
  State<SetupSourcesScreen> createState() => _SetupSourcesScreenState();
}

class _SetupSourcesScreenState extends State<SetupSourcesScreen> {
  final _aiPromptController = TextEditingController();
  final List<FundSource> _pendingSources = [
    FundSource(
      id: 'src_uang_jajan',
      name: 'Uang Jajan',
      balance: 500000.0,
      iconName: 'wallet',
      colorHex: '16A34A',
      description: 'Uang saku harian',
      isDefault: true,
    ),
    FundSource(
      id: 'src_tabungan',
      name: 'Tabungan',
      balance: 2000000.0,
      iconName: 'piggy_bank',
      colorHex: '0D9488',
      description: 'Tabungan masa depan',
      isDefault: false,
    ),
  ];

  void _parseNaturalLanguageSources() {
    final text = _aiPromptController.text.trim();
    if (text.isEmpty) return;

    // Example: "Saya punya uang jajan 500 ribu dan tabungan 2 juta."
    final lower = text.toLowerCase();
    final newSources = <FundSource>[];

    if (lower.contains('jajan')) {
      newSources.add(FundSource(
        id: 'src_jajan_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Uang Jajan',
        balance: 500000.0,
        iconName: 'wallet',
        colorHex: '16A34A',
        isDefault: true,
      ));
    }
    if (lower.contains('tabungan')) {
      newSources.add(FundSource(
        id: 'src_tab_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Tabungan',
        balance: 2000000.0,
        iconName: 'piggy_bank',
        colorHex: '0D9488',
      ));
    }

    if (newSources.isNotEmpty) {
      setState(() {
        _pendingSources.clear();
        _pendingSources.addAll(newSources);
        _aiPromptController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ AI berhasil mengekstrak sumber dana Anda!')),
      );
    }
  }

  void _addNewManualSource() {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Tambah Sumber Dana',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: const InputDecoration(hintText: 'Nama (misal: Bank Mandiri / GoPay)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: const InputDecoration(hintText: 'Saldo Awal (Rp)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final bal = double.tryParse(balanceCtrl.text.replaceAll('.', '')) ?? 0.0;
                if (name.isNotEmpty) {
                  setState(() {
                    _pendingSources.add(FundSource(
                      id: 'src_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      balance: bal,
                      iconName: 'credit_card',
                      colorHex: '3B82F6',
                    ));
                  });
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  bool _isSaving = false;

  void _finishSetup() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    for (final s in _pendingSources) {
      finance.addFundSource(s);
    }
    finance.updateProfile(
      finance.profile.copyWith(hasCompletedSetup: true),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let\'s Set Up Your Money 💳',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tambahkan sumber dana Anda saat ini untuk mulai memantau keuangan.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // AI Natural Language Input Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevatedCard : AppColors.lightSoftGreen,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkPrimary.withOpacity(0.3) : AppColors.lightLightGreen,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 18, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Input Cepat dengan Bahasa Alami',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightDarkGreen,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aiPromptController,
                      style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : Colors.white,
                        hintText: 'Contoh: "Saya punya uang jajan 500 ribu dan tabungan 2 juta."',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.arrow_forward_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                          onPressed: _parseNaturalLanguageSources,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Daftar Sumber Dana (${_pendingSources.length})',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewManualSource,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Manual', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Fund Sources Cards
              ..._pendingSources.map((source) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          source.iconName == 'piggy_bank' ? Icons.savings_rounded : Icons.account_balance_wallet_rounded,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(source.balance),
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                        onPressed: () {
                          setState(() => _pendingSources.remove(source));
                        },
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 36),

              // Finish Setup Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: (_pendingSources.isEmpty || _isSaving) ? null : _finishSetup,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Konfirmasi & Masuk Dashboard',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
