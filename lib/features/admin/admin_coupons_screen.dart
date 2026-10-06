import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../models/coupon_model.dart';
import '../../models/saas_models.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/saas_backend_service.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final _saas = SaaSBackendService();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  bool _isLoading = true;
  List<Coupon> _coupons = [];
  List<Plan> _availablePlans = [];
  String _searchQuery = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final coupons = await _saas.getCoupons();
      final plans = await _saas.getPlans(includeInactive: true);

      if (mounted) {
        setState(() {
          _coupons = coupons;
          _availablePlans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data kupon: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showCouponDialog({Coupon? couponToEdit}) {
    final isEditing = couponToEdit != null;
    final codeCtrl = TextEditingController(text: couponToEdit?.code ?? '');
    final descCtrl = TextEditingController(text: couponToEdit?.description ?? '');
    final valCtrl = TextEditingController(
      text: couponToEdit != null ? couponToEdit.discountValue.toInt().toString() : '',
    );
    final usageLimitCtrl = TextEditingController(
      text: couponToEdit?.usageLimit != null ? couponToEdit!.usageLimit.toString() : '100',
    );
    final perUserLimitCtrl = TextEditingController(
      text: couponToEdit?.perUserLimit.toString() ?? '1',
    );
    final minPurchaseCtrl = TextEditingController(
      text: couponToEdit?.minimumPurchase.toInt().toString() ?? '0',
    );

    CouponDiscountType discountType = couponToEdit?.discountType ?? CouponDiscountType.percentage;
    DateTime startsAt = couponToEdit?.startsAt ?? DateTime.now();
    DateTime? expiresAt = couponToEdit?.expiresAt ?? DateTime.now().add(const Duration(days: 30));
    bool isActive = couponToEdit?.isActive ?? true;
    List<String> selectedPlanIds = List.from(couponToEdit?.applicablePlanIds ?? []);

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
              constraints: BoxConstraints(maxHeight: MediaQuery.of(modalCtx).size.height * 0.88),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                          child: Icon(
                            isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                            color: AppColors.emerald,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Edit Kupon Diskon' : 'Buat Kupon Diskon Baru',
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
                            Expanded(child: Text(formError!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                          ],
                        ),
                      ),
                    // Code
                    Text('Kode Kupon (Uppercase)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                    const SizedBox(height: 6),
                    TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Misal: HEMAT20',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Description
                    Text('Deskripsi Kupon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Diskon 20% menyambut gajian',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Discount Type & Value Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tipe Diskon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<CouponDiscountType>(
                                    value: discountType,
                                    isExpanded: true,
                                    dropdownColor: bg,
                                    items: const [
                                      DropdownMenuItem(value: CouponDiscountType.percentage, child: Text('Persen (%)')),
                                      DropdownMenuItem(value: CouponDiscountType.fixed, child: Text('Nominal (Rp)')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => discountType = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nilai Diskon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                              const SizedBox(height: 6),
                              TextField(
                                controller: valCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixText: discountType == CouponDiscountType.fixed ? 'Rp ' : '% ',
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Limits Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Batas Total Kupon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                              const SizedBox(height: 6),
                              TextField(
                                controller: usageLimitCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Opsional',
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Limit Per User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                              const SizedBox(height: 6),
                              TextField(
                                controller: perUserLimitCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Minimum Purchase
                    Text('Minimum Transaksi (IDR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                    const SizedBox(height: 6),
                    TextField(
                      controller: minPurchaseCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Expiry Date Selection
                    Text('Tanggal Kedaluwarsa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: modalCtx,
                          initialDate: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 1825)),
                        );
                        if (picked != null) {
                          setModalState(() => expiresAt = picked.add(const Duration(hours: 23, minutes: 59)));
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF141916) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.emerald),
                            const SizedBox(width: 10),
                            Text(
                              expiresAt != null
                                  ? DateFormat('dd MMMM yyyy', 'id_ID').format(expiresAt!)
                                  : 'Tidak terbatas',
                              style: TextStyle(fontSize: 14, color: textP, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Applicable Plans Multi-select
                    Text('Paket Yang Berlaku', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availablePlans.map((p) {
                        final isSelected = selectedPlanIds.contains(p.id);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(p.name),
                          selectedColor: AppColors.emerald.withOpacity(0.2),
                          checkmarkColor: AppColors.emerald,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.emerald : textP,
                          ),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedPlanIds.add(p.id);
                              } else {
                                selectedPlanIds.remove(p.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    // Active toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.emerald,
                      title: Text('Status Kupon Aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textP)),
                      subtitle: const Text('Kupon nonaktif langsung ditolak saat checkout', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      value: isActive,
                      onChanged: (val) => setModalState(() => isActive = val),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
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
                              final cleanCode = codeCtrl.text.trim().toUpperCase();
                              final val = double.tryParse(valCtrl.text.trim());
                              final usageLimit = int.tryParse(usageLimitCtrl.text.trim());
                              final perUserLimit = int.tryParse(perUserLimitCtrl.text.trim()) ?? 1;
                              final minPurchase = double.tryParse(minPurchaseCtrl.text.trim()) ?? 0.0;

                              if (cleanCode.isEmpty) {
                                setModalState(() => formError = 'Kode kupon wajib diisi.');
                                return;
                              }
                              if (val == null || val <= 0) {
                                setModalState(() => formError = 'Nilai diskon harus lebih besar dari 0.');
                                return;
                              }
                              if (discountType == CouponDiscountType.percentage && val > 100) {
                                setModalState(() => formError = 'Diskon persen tidak boleh melebihi 100%.');
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                                formError = null;
                              });

                              try {
                                final c = Coupon(
                                  id: couponToEdit?.id ?? 'cpn_${DateTime.now().millisecondsSinceEpoch}',
                                  code: cleanCode,
                                  description: descCtrl.text.trim(),
                                  discountType: discountType,
                                  discountValue: val,
                                  startsAt: startsAt,
                                  expiresAt: expiresAt,
                                  usageLimit: usageLimit ?? 100,
                                  usageCount: couponToEdit?.usageCount ?? 0,
                                  perUserLimit: perUserLimit,
                                  minimumPurchase: minPurchase,
                                  applicablePlanIds: selectedPlanIds,
                                  isActive: isActive,
                                );

                                if (isEditing) {
                                  await _saas.updateCoupon(c);
                                } else {
                                  await _saas.createCoupon(c);
                                }

                                if (modalCtx.mounted) Navigator.pop(modalCtx);
                                _loadData();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Kupon $cleanCode berhasil ${isEditing ? "diperbarui" : "dibuat"}.'),
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
                                : Text(isEditing ? 'Simpan' : 'Buat Kupon', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                  'Hanya Administrator yang memiliki wewenang untuk mengelola kupon diskon.',
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

    final filtered = _coupons.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Coupons',
          style: TextStyle(color: textP, fontWeight: FontWeight.w800, fontFamily: 'Plus Jakarta Sans'),
        ),
        iconTheme: IconThemeData(color: textP),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kupon Baru', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _showCouponDialog(),
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
                          onPressed: _loadData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Cari kode kupon atau deskripsi...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Semua Kupon (${filtered.length})',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textP,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.confirmation_number_outlined, size: 54, color: isDark ? Colors.white24 : Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('Belum ada kupon ditemukan.', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600])),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtered.map((c) => _buildCouponCard(c, cardBg, textP, isDark)),
                    const SizedBox(height: 80),
                  ],
                ),
    );
  }

  Widget _buildCouponCard(Coupon coupon, Color cardBg, Color textP, bool isDark) {
    final statusColor = !coupon.isActive
        ? Colors.grey
        : coupon.isExpired
            ? Colors.red
            : Colors.green;
    final statusLabel = !coupon.isActive
        ? 'NONAKTIF'
        : coupon.isExpired
            ? 'EXPIRED'
            : 'AKTIF';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                ),
                child: Text(
                  coupon.code,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.emerald,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                coupon.discountLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textP,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            coupon.description.isNotEmpty ? coupon.description : 'Tidak ada deskripsi kupon.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 12),
          // Info row: usage and min purchase
          Row(
            children: [
              Icon(Icons.people_outline_rounded, size: 14, color: isDark ? Colors.white60 : Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Terpakai: ${coupon.usageCount} / ${coupon.usageLimit > 0 ? coupon.usageLimit : '∞'}',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]),
              ),
              const SizedBox(width: 14),
              Icon(Icons.shopping_bag_outlined, size: 14, color: isDark ? Colors.white60 : Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Min. ${_currency.format(coupon.minimumPurchase)}',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (coupon.expiresAt != null)
            Row(
              children: [
                Icon(Icons.event_outlined, size: 14, color: isDark ? Colors.white60 : Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Berlaku hingga: ${DateFormat('dd MMM yyyy', 'id_ID').format(coupon.expiresAt!)}',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]),
                ),
              ],
            ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: coupon.isActive ? Colors.orange : AppColors.emerald,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: Icon(coupon.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 16),
                label: Text(coupon.isActive ? 'Nonaktifkan' : 'Aktifkan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: () async {
                  final updated = Coupon(
                    id: coupon.id,
                    code: coupon.code,
                    description: coupon.description,
                    discountType: coupon.discountType,
                    discountValue: coupon.discountValue,
                    startsAt: coupon.startsAt,
                    expiresAt: coupon.expiresAt,
                    usageLimit: coupon.usageLimit,
                    usageCount: coupon.usageCount,
                    perUserLimit: coupon.perUserLimit,
                    minimumPurchase: coupon.minimumPurchase,
                    applicablePlanIds: coupon.applicablePlanIds,
                    isActive: !coupon.isActive,
                  );
                  await _saas.updateCoupon(updated);
                  _loadData();
                },
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.emerald,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: () => _showCouponDialog(couponToEdit: coupon),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
