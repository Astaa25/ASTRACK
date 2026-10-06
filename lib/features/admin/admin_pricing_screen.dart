import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../models/coupon_model.dart';
import '../../models/saas_models.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/saas_backend_service.dart';

class AdminPricingScreen extends StatefulWidget {
  const AdminPricingScreen({super.key});

  @override
  State<AdminPricingScreen> createState() => _AdminPricingScreenState();
}

class _AdminPricingScreenState extends State<AdminPricingScreen> {
  final _saas = SaaSBackendService();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  bool _isLoading = true;
  List<Plan> _plans = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plans = await _saas.getPlans(includeInactive: true);
      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat produk: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showEditPlanDialog(Plan plan) {
    final nameCtrl = TextEditingController(text: plan.name);
    final priceCtrl = TextEditingController(text: plan.monthlyPrice.toInt().toString());
    final descCtrl = TextEditingController(text: plan.description);
    int selectedDuration = plan.durationMonths;
    bool isRec = plan.isRecommended;
    bool isActive = plan.isActive;
    String? formError;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Provider.of<ThemeProvider>(modalCtx, listen: false).isDarkMode;
          final bg = isDark ? const Color(0xFF1E2421) : Colors.white;
          final textP = isDark ? Colors.white : const Color(0xFF1E293B);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: AppColors.emerald, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Edit Produk Pricing',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textP,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (formError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formError!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Product Name
                    Text('Nama Produk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Price
                    Text('Harga (IDR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(fontWeight: FontWeight.w700, color: textP),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Duration
                    Text('Durasi Paket', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedDuration,
                          isExpanded: true,
                          dropdownColor: bg,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 Bulan')),
                            DropdownMenuItem(value: 3, child: Text('3 Bulan')),
                            DropdownMenuItem(value: 6, child: Text('6 Bulan')),
                            DropdownMenuItem(value: 12, child: Text('12 Bulan (1 Tahun)')),
                            DropdownMenuItem(value: 120, child: Text('Lifetime')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedDuration = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Description
                    Text('Deskripsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Switch Toggles
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.emerald,
                      title: Text('Tandai sebagai Recommended', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textP)),
                      subtitle: const Text('Hanya satu paket aktif yang menjadi recommended', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      value: isRec,
                      onChanged: (val) => setModalState(() => isRec = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.emerald,
                      title: Text('Status Aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textP)),
                      subtitle: const Text('Paket nonaktif tidak dapat dibeli user baru', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      value: isActive,
                      onChanged: (val) => setModalState(() => isActive = val),
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                            ),
                            onPressed: () => Navigator.pop(modalCtx),
                            child: Text('Batal', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: isSaving ? null : () async {
                              final price = double.tryParse(priceCtrl.text.trim());
                              if (price == null || price < 0) {
                                setModalState(() => formError = 'Harga tidak boleh kosong atau negatif.');
                                return;
                              }
                              if (nameCtrl.text.trim().isEmpty) {
                                setModalState(() => formError = 'Nama produk tidak boleh kosong.');
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                                formError = null;
                              });

                              try {
                                await _saas.updatePlanPricing(
                                  planId: plan.id,
                                  newPrice: price,
                                  name: nameCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  durationMonths: selectedDuration,
                                  isRecommended: isRec,
                                  isActive: isActive,
                                  adminId: 'admin_session',
                                );

                                if (modalCtx.mounted) Navigator.pop(modalCtx);
                                _loadPlans();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Harga produk ${plan.name} berhasil diperbarui.'),
                                      backgroundColor: AppColors.emerald,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (err) {
                                setModalState(() {
                                  isSaving = false;
                                  formError = err.toString().replaceAll('Exception: ', '');
                                });
                              }
                            },
                            child: isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPriceHistorySheet(Plan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Provider.of<ThemeProvider>(sheetCtx, listen: false).isDarkMode;
        final bg = isDark ? const Color(0xFF1E2421) : Colors.white;
        final textP = isDark ? Colors.white : const Color(0xFF1E293B);

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_rounded, color: Colors.blue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audit Price History: ${plan.name}',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textP,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Riwayat perubahan harga yang immutable',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PENTING: Transaksi lama tetap menggunakan harga historis dan tidak terpengaruh.',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.amber[200] : Colors.amber[900], fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<PlanPriceHistory>>(
                  future: _saas.getPriceHistory(plan.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text('Belum ada riwayat perubahan harga.', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500])),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final h = history[idx];
                        final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(h.changedAt);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.currency_exchange_rounded, color: AppColors.emerald, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _currency.format(h.oldPrice),
                                          style: TextStyle(
                                            fontSize: 13,
                                            decoration: TextDecoration.lineThrough,
                                            color: isDark ? Colors.white38 : Colors.grey[500],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          _currency.format(h.newPrice),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: textP,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Diubah oleh ${h.changedBy} • $dateStr',
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8);
    final cardBg = isDark ? const Color(0xFF1E2421) : Colors.white;
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    FinanceProvider? finance;
    try {
      finance = Provider.of<FinanceProvider>(context, listen: false);
    } catch (_) {}

    if (finance != null && !finance.profile.isAdmin) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          title: Text('Akses Ditolak', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: textP),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gpp_bad_rounded, size: 64, color: AppColors.expense),
                const SizedBox(height: 16),
                Text('Akses Ditolak', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textP)),
                const SizedBox(height: 8),
                Text(
                  'Hanya Administrator yang memiliki wewenang untuk membuka halaman ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                  child: const Text('Kembali', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Product Pricing',
          style: TextStyle(color: textP, fontWeight: FontWeight.w800, fontFamily: 'Plus Jakarta Sans'),
        ),
        iconTheme: IconThemeData(color: textP),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: _loadPlans,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.emerald))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: textP)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                          onPressed: _loadPlans,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Information Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.emerald.withOpacity(isDark ? 0.2 : 0.1),
                            AppColors.emerald.withOpacity(isDark ? 0.05 : 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.emerald.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.price_change_rounded, color: AppColors.emerald, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dynamic Product Management',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: textP,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Semua perubahan harga tersinkronisasi realtime ke Paywall & Checkout tanpa rilis aplikasi ulang.',
                                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Daftar Produk (${_plans.length})',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textP,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._plans.map((p) => _buildPlanCard(p, cardBg, textP, isDark)),
                  ],
                ),
    );
  }

  Widget _buildPlanCard(Plan plan, Color cardBg, Color textP, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: plan.isRecommended
              ? AppColors.emerald.withOpacity(0.5)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
          width: plan.isRecommended ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      plan.name.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: textP,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (plan.isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.emerald.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 13, color: AppColors.emerald),
                            SizedBox(width: 4),
                            Text(
                              'RECOMMENDED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emerald),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: plan.isActive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  plan.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: plan.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.description.isNotEmpty ? plan.description : 'Tidak ada deskripsi paket.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currency.format(plan.monthlyPrice),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textP,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                plan.durationLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                ),
                icon: const Icon(Icons.history_rounded, size: 16),
                label: const Text('Riwayat Harga', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: () => _showPriceHistorySheet(plan),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit Produk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: () => _showEditPlanDialog(plan),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
