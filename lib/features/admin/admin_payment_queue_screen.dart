import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/theme_provider.dart';
import '../../services/payment/manual_qris_service.dart';
import '../../services/payment/payment_models.dart';
import 'admin_gateway_config_screen.dart';

class AdminPaymentQueueScreen extends StatefulWidget {
  const AdminPaymentQueueScreen({super.key});

  @override
  State<AdminPaymentQueueScreen> createState() => _AdminPaymentQueueScreenState();
}

class _AdminPaymentQueueScreenState extends State<AdminPaymentQueueScreen> {
  final _qrisService = ManualQrisService();
  bool _isLoading = true;
  List<PaymentOrder> _orders = [];
  PaymentStatus? _selectedFilter = PaymentStatus.claimed; // Default focus on queue to verify
  PaymentOrder? _selectedOrder;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final list = await _qrisService.getAdminQueue(statusFilter: _selectedFilter);
    if (!mounted) return;
    setState(() {
      _orders = list;
      if (_selectedOrder != null) {
        _selectedOrder = list.cast<PaymentOrder?>().firstWhere(
          (o) => o?.orderId == _selectedOrder!.orderId,
          orElse: () => list.isNotEmpty ? list.first : null,
        );
      } else if (list.isNotEmpty) {
        _selectedOrder = list.first;
      }
      _isLoading = false;
    });
  }

  void _onFilterChanged(PaymentStatus? filter) {
    setState(() {
      _selectedFilter = filter;
      _selectedOrder = null;
    });
    _loadOrders();
  }

  Future<void> _handleApprove(PaymentOrder order) async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppColors.income, size: 24),
              const SizedBox(width: 10),
              Text(
                'Setujui Pembayaran?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konfirmasi aktivasi langganan untuk:',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Order ID: ${order.orderId}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
              Text(
                'Nominal: ${CurrencyFormatter.format(order.amount)} (Kode: ${order.uniqueCode ?? 0})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.income),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Perpanjangan otomatis bersifat IDEMPOTENT. Jika pengguna masih memiliki paket aktif, masa aktif akan diperpanjang dari tanggal kedaluwarsa terakhir.',
                  style: TextStyle(fontSize: 12, color: AppColors.income, height: 1.3),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.income,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ACC & Aktifkan Pro', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final updated = await _qrisService.approveOrder(
        orderId: order.orderId,
        adminId: 'admin_dashboard',
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _selectedOrder = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembayaran ${order.orderId} BERHASIL DISETUJUI. Langganan aktif!'),
          backgroundColor: AppColors.income,
        ),
      );

      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyetujui: $e'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _handleReject(PaymentOrder order) async {
    if (_isProcessing) return;

    final reasonController = TextEditingController();
    final presets = [
      'Nominal transfer tidak sesuai (kode unik keliru)',
      'Bukti transfer tidak valid atau tidak terbaca',
      'Mutasi rekening bank belum ditemukan',
      'Pembayaran sudah kedaluwarsa',
    ];

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String? selectedPreset;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: AppColors.expense, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Tolak Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih atau tulis alasan penolakan (Wajib diisi):',
                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 12),
                    ...presets.map((preset) => RadioListTile<String>(
                          value: preset,
                          groupValue: selectedPreset,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(preset, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedPreset = val;
                              reasonController.text = val ?? '';
                            });
                          },
                        )),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Alasan penolakan khusus...',
                        hintStyle: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        filled: true,
                        fillColor: isDark ? AppColors.darkDeepBg : AppColors.lightBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expense,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final text = reasonController.text.trim();
                    if (text.length >= 5) {
                      Navigator.pop(ctx, text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alasan penolakan minimal 5 karakter!'), backgroundColor: AppColors.expense),
                      );
                    }
                  },
                  child: const Text('Tolak Pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );

    if (reason == null || reason.trim().length < 5) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final updated = await _qrisService.rejectOrder(
        orderId: order.orderId,
        reason: reason.trim(),
        adminId: 'admin_dashboard',
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _selectedOrder = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembayaran ${order.orderId} DITOLAK.'),
          backgroundColor: AppColors.expense,
        ),
      );

      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menolak: $e'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  void _showProofViewer(BuildContext context, String proofUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bukti Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white70, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      proofUrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textS = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8);
    final isTablet = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Antrean Verifikasi Pembayaran',
          style: TextStyle(color: textP, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textP),
        actions: [
          IconButton(
            icon: Icon(Icons.hub_rounded, color: primary),
            tooltip: 'Konfigurasi Gateway & Mode',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGatewayConfigScreen()));
              _loadOrders();
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primary),
            tooltip: 'Segarkan Antrean',
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterTabs(isDark, primary, textP, textS),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primary))
                  : isTablet
                      ? _buildTabletTwoPane(isDark, primary, textP, textS)
                      : _buildPhoneView(isDark, primary, textP, textS),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark, Color primary, Color textP, Color textS) {
    final filters = [
      (PaymentStatus.claimed, 'Verifikasi'),
      (null, 'Semua'),
      (PaymentStatus.paid, 'Disetujui'),
      (PaymentStatus.rejected, 'Ditolak'),
      (PaymentStatus.pending, 'Menunggu'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.$2),
              selected: isSelected,
              selectedColor: primary,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isSelected ? (isDark ? Colors.black : Colors.white) : textS,
              ),
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (_) => _onFilterChanged(f.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhoneView(bool isDark, Color primary, Color textP, Color textS) {
    if (_orders.isEmpty) {
      return _buildEmptyState(textP, textS);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (ctx, i) {
        final order = _orders[i];
        return _buildOrderCard(order, isDark, primary, textP, textS, onTap: () {
          _showOrderDetailSheet(context, order, isDark, primary, textP, textS);
        });
      },
    );
  }

  Widget _buildTabletTwoPane(bool isDark, Color primary, Color textP, Color textS) {
    return Row(
      children: [
        // Master List (Left Pane)
        SizedBox(
          width: 340,
          child: _orders.isEmpty
              ? _buildEmptyState(textP, textS)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (ctx, i) {
                    final order = _orders[i];
                    final isSelected = _selectedOrder?.orderId == order.orderId;
                    return _buildOrderCard(
                      order,
                      isDark,
                      primary,
                      textP,
                      textS,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedOrder = order),
                    );
                  },
                ),
        ),
        VerticalDivider(width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        // Detail Pane (Right Pane)
        Expanded(
          child: _selectedOrder == null
              ? Center(
                  child: Text('Pilih order untuk melihat detail', style: TextStyle(color: textS)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildDetailContent(_selectedOrder!, isDark, primary, textP, textS),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    PaymentOrder order,
    bool isDark,
    Color primary,
    Color textP,
    Color textS, {
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    Color badgeColor;
    switch (order.status) {
      case PaymentStatus.claimed:
        badgeColor = Colors.blue.shade700;
        break;
      case PaymentStatus.paid:
        badgeColor = AppColors.income;
        break;
      case PaymentStatus.rejected:
        badgeColor = AppColors.expense;
        break;
      default:
        badgeColor = Colors.amber.shade800;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? primary.withValues(alpha: 0.12)
          : (isDark ? AppColors.darkCard : Colors.white),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 11, color: textS),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                order.orderId,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textP,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Paket: ${order.planId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: textS),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.format(order.amount),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (order.proofNotes != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Catatan: "${order.proofNotes}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: textS),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailSheet(
    BuildContext context,
    PaymentOrder order,
    bool isDark,
    Color primary,
    Color textP,
    Color textS,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: _buildDetailContent(order, isDark, primary, textP, textS),
          ),
        );
      },
    );
  }

  Widget _buildDetailContent(
    PaymentOrder order,
    bool isDark,
    Color primary,
    Color textP,
    Color textS,
  ) {
    final base = order.baseAmount ?? order.amount;
    final discount = order.discountAmount ?? 0.0;
    final code = order.uniqueCode ?? 0;
    final cardBg = isDark ? AppColors.darkElevatedCard : AppColors.lightBg;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Pembayaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textP),
                  ),
                  Text(order.orderId, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: textS)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (order.status == PaymentStatus.paid ? AppColors.income : (order.status == PaymentStatus.claimed ? Colors.blue : Colors.amber)).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                order.status.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: order.status == PaymentStatus.paid ? AppColors.income : (order.status == PaymentStatus.claimed ? Colors.blue.shade700 : Colors.amber.shade800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _detailRow('User ID', order.userId, textS, textP),
              const SizedBox(height: 8),
              _detailRow('Paket Langganan', order.planId, textS, textP),
              const SizedBox(height: 8),
              _detailRow('Harga Normal', CurrencyFormatter.format(base), textS, textP),
              if (discount > 0) ...[
                const SizedBox(height: 8),
                _detailRow('Diskon Kupon (${order.couponCode ?? ''})', '- ${CurrencyFormatter.format(discount)}', AppColors.income, AppColors.income),
              ],
              const SizedBox(height: 8),
              _detailRow('Kode Unik Transaksi', '+ Rp $code', Colors.amber.shade800, Colors.amber.shade800),
              const Divider(height: 20),
              _detailRow('Total Transfer Presisi', CurrencyFormatter.format(order.amount), textP, primary, isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (order.proofUrl != null && order.proofUrl!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bukti Transfer Pengguna', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textP)),
                    TextButton.icon(
                      icon: const Icon(Icons.fullscreen_rounded, size: 16),
                      label: const Text('Buka'),
                      onPressed: () => _showProofViewer(context, order.proofUrl!),
                    ),
                  ],
                ),
                Text('Berkas: ${order.proofUrl}', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: textS)),
                if (order.proofNotes != null) ...[
                  const SizedBox(height: 6),
                  Text('Catatan: "${order.proofNotes}"', style: TextStyle(fontSize: 12, color: textP)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (order.rejectionReason != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.expense.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Alasan Penolakan: ${order.rejectionReason}',
              style: const TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Action Buttons
        if (order.status != PaymentStatus.paid) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: const BorderSide(color: AppColors.expense),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: _isProcessing ? null : () => _handleReject(order),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('ACC Pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: _isProcessing ? null : () => _handleApprove(order),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, color: AppColors.income, size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Berhasil Diverifikasi',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.income, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailRow(String label, String value, Color labelColor, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textP, Color textS) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Antrean Pembayaran',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textP),
            ),
            const SizedBox(height: 6),
            Text(
              'Semua klaim pembayaran telah diproses atau belum ada pesanan baru.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textS),
            ),
          ],
        ),
      ),
    );
  }
}
