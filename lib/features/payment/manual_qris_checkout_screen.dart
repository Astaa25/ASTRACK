import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/saas_models.dart';
import '../../providers/theme_provider.dart';
import '../../services/payment/manual_qris_service.dart';
import '../../services/payment/payment_models.dart';

class ManualQrisCheckoutScreen extends StatefulWidget {
  final PaymentOrder order;
  final Plan plan;

  const ManualQrisCheckoutScreen({
    super.key,
    required this.order,
    required this.plan,
  });

  @override
  State<ManualQrisCheckoutScreen> createState() => _ManualQrisCheckoutScreenState();
}

class _ManualQrisCheckoutScreenState extends State<ManualQrisCheckoutScreen> {
  final _qrisService = ManualQrisService();
  final _picker = ImagePicker();
  final _notesController = TextEditingController();

  late PaymentOrder _currentOrder;
  String? _proofPath;
  bool _isClaiming = false;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    final diff = _currentOrder.expiresAt.difference(DateTime.now());
    _remainingTime = diff.isNegative ? Duration.zero : diff;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final remaining = _currentOrder.expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        setState(() {
          _remainingTime = Duration.zero;
          _currentOrder = _currentOrder.copyWith(status: PaymentStatus.expired);
        });
      } else {
        setState(() {
          _remainingTime = remaining;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _pickProofImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _proofPath = picked.path;
        });
      }
    } catch (_) {
      // Offline fallback mock path for desktop/test environments
      setState(() {
        _proofPath = 'mock_receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  Future<void> _handleClaimPayment() async {
    if (_isClaiming) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konfirmasi Pengiriman Bukti',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pastikan Anda telah mentransfer tepat ${CurrencyFormatter.format(_currentOrder.amount)} (termasuk 3 digit kode unik). Verifikasi manual diproses admin dalam waktu 5-15 menit.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Periksa Kembali'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Ya, Sudah Transfer', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isClaiming = true);
    HapticFeedback.mediumImpact();

    try {
      final updated = await _qrisService.claimPayment(
        orderId: _currentOrder.orderId,
        proofUrl: _proofPath ?? 'direct_claim_submitted',
        proofNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        userId: _currentOrder.userId,
      );

      if (!mounted) return;
      setState(() {
        _currentOrder = updated;
        _isClaiming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klaim pembayaran berhasil! Admin sedang memverifikasi transfer Anda.'),
          backgroundColor: AppColors.income,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isClaiming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim klaim: $e'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
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
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: Text(
          'Pembayaran QRIS',
          style: TextStyle(color: textP, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8),
        elevation: 0,
        iconTheme: IconThemeData(color: textP),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusHeader(isDark, primary, textP, textS),
              const SizedBox(height: 20),
              _buildAmountBreakdownCard(cardBg, borderColor, isDark, primary, textP, textS),
              const SizedBox(height: 20),
              _buildQrisCard(cardBg, borderColor, isDark, primary, textP, textS),
              const SizedBox(height: 20),
              _buildBankAlternativeCard(cardBg, borderColor, isDark, primary, textP, textS),
              const SizedBox(height: 20),
              _buildClaimSection(cardBg, borderColor, isDark, primary, textP, textS),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(bool isDark, Color primary, Color textP, Color textS) {
    Color badgeBg;
    Color badgeColor;
    IconData icon;
    String label;

    switch (_currentOrder.status) {
      case PaymentStatus.pending:
        badgeBg = Colors.amber.withValues(alpha: isDark ? 0.2 : 0.12);
        badgeColor = Colors.amber.shade800;
        icon = Icons.timer_outlined;
        label = 'Menunggu Pembayaran';
        break;
      case PaymentStatus.claimed:
        badgeBg = Colors.blue.withValues(alpha: isDark ? 0.2 : 0.12);
        badgeColor = Colors.blue.shade700;
        icon = Icons.hourglass_top_rounded;
        label = 'Menunggu Verifikasi Admin';
        break;
      case PaymentStatus.paid:
        badgeBg = AppColors.income.withValues(alpha: isDark ? 0.2 : 0.12);
        badgeColor = AppColors.income;
        icon = Icons.check_circle_rounded;
        label = 'Pembayaran Berhasil (Aktif)';
        break;
      case PaymentStatus.rejected:
        badgeBg = AppColors.expense.withValues(alpha: isDark ? 0.2 : 0.12);
        badgeColor = AppColors.expense;
        icon = Icons.cancel_rounded;
        label = 'Pembayaran Ditolak';
        break;
      case PaymentStatus.expired:
      default:
        badgeBg = Colors.grey.withValues(alpha: 0.15);
        badgeColor = Colors.grey;
        icon = Icons.alarm_off_rounded;
        label = 'Kedaluwarsa';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: badgeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: badgeColor),
                ),
                if (_currentOrder.status == PaymentStatus.pending) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sisa waktu: ${_formatDuration(_remainingTime)}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
                if (_currentOrder.status == PaymentStatus.rejected && _currentOrder.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Alasan: ${_currentOrder.rejectionReason}',
                    style: TextStyle(fontSize: 12, color: badgeColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBreakdownCard(
    Color cardBg,
    Color borderColor,
    bool isDark,
    Color primary,
    Color textP,
    Color textS,
  ) {
    final base = _currentOrder.baseAmount ?? _currentOrder.amount;
    final discount = _currentOrder.discountAmount ?? 0.0;
    final code = _currentOrder.uniqueCode ?? 0;
    final finalAmount = _currentOrder.amount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Rincian Tagihan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textP),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.plan.name,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _rowItem('Harga Paket (${widget.plan.durationLabel})', CurrencyFormatter.format(base), textS, textP),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _rowItem(
              'Diskon Kupon (${_currentOrder.couponCode ?? ''})',
              '- ${CurrencyFormatter.format(discount)}',
              AppColors.income,
              AppColors.income,
            ),
          ],
          const SizedBox(height: 8),
          _rowItem(
            'Kode Unik Transaksi',
            '+ Rp $code',
            Colors.amber.shade800,
            Colors.amber.shade800,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pembayaran Presisi', style: TextStyle(fontSize: 12, color: textS)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(finalAmount),
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary.withValues(alpha: 0.15),
                  foregroundColor: primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onPressed: () => _copyToClipboard(
                  finalAmount.toInt().toString(),
                  'Nominal Rp ${finalAmount.toInt()} disalin ke clipboard!',
                ),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Salin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PENTING: Transfer harus PERSIS sampai 3 digit kode unik (+Rp $code) agar verifikasi pembayaran dapat dicocokkan.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowItem(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: labelColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildQrisCard(
    Color cardBg,
    Color borderColor,
    bool isDark,
    Color primary,
    Color textP,
    Color textS,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'QRIS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'ASTRACK OFFICIAL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textP),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('NMID: ID1026001234567', style: TextStyle(fontSize: 12, color: textS)),
          const SizedBox(height: 20),
          // Styled QR Code Graphic Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Grid mock pattern of QR
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                        ),
                        itemCount: 49,
                        itemBuilder: (ctx, i) {
                          final isWhite = (i % 3 == 0) || (i % 7 == 2) || (i > 18 && i < 28 && i % 2 == 1);
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isWhite ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                      // Center Logo
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: primary, width: 2),
                        ),
                        child: Icon(Icons.wallet_rounded, color: primary, size: 24),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentOrder.orderId,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mendukung GoPay, OVO, DANA, ShopeePay, BCA, Livin, & Semua Bank',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textS, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAlternativeCard(
    Color cardBg,
    Color borderColor,
    bool isDark,
    Color primary,
    Color textP,
    Color textS,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer Bank Manual',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textP),
          ),
          const SizedBox(height: 12),
          _bankAccountTile('BCA', '1234-5678-90', 'PT Astrack Teknologi Finansial', textP, textS, primary),
          const SizedBox(height: 12),
          _bankAccountTile('Mandiri', '0987-6543-21', 'PT Astrack Teknologi Finansial', textP, textS, primary),
        ],
      ),
    );
  }

  Widget _bankAccountTile(
    String bankName,
    String accNumber,
    String accHolder,
    Color textP,
    Color textS,
    Color primary,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: primary),
                ),
                const SizedBox(height: 2),
                Text(
                  accNumber,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textP,
                  ),
                ),
                Text(accHolder, style: TextStyle(fontSize: 11, color: textS)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy_rounded, color: primary, size: 20),
            onPressed: () => _copyToClipboard(
              accNumber.replaceAll('-', ''),
              'Nomor rekening $bankName disalin!',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimSection(
    Color cardBg,
    Color borderColor,
    bool isDark,
    Color primary,
    Color textP,
    Color textS,
  ) {
    final isClaimed = _currentOrder.status == PaymentStatus.claimed;
    final isPaid = _currentOrder.status == PaymentStatus.paid;
    final isExpired = _currentOrder.isExpired || _currentOrder.status == PaymentStatus.expired;

    if (isPaid) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.income.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.income),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 48),
            const SizedBox(height: 12),
            Text(
              'Langganan ${widget.plan.name} Aktif!',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.income),
            ),
            const SizedBox(height: 6),
            Text(
              'Terima kasih! Seluruh fitur premium telah terbuka dan dapat digunakan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textS),
            ),
          ],
        ),
      );
    }

    if (isClaimed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade600),
        ),
        child: Column(
          children: [
            Icon(Icons.hourglass_bottom_rounded, color: Colors.blue.shade700, size: 44),
            const SizedBox(height: 12),
            Text(
              'Bukti Pembayaran Sudah Dikirim',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.blue.shade800),
            ),
            const SizedBox(height: 6),
            Text(
              'Admin sedang memverifikasi antrean transfer Anda. Halaman ini akan terupdate secara otomatis.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textS),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Konfirmasi Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textP),
          ),
          const SizedBox(height: 8),
          Text(
            'Setelah melakukan transfer, tekan tombol di bawah ini agar antrean verifikasi Anda langsung diproses.',
            style: TextStyle(fontSize: 13, color: textS, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            style: TextStyle(color: textP, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Catatan / Nama Rekening Pengirim (Opsional)',
              labelStyle: TextStyle(color: textS, fontSize: 13),
              filled: true,
              fillColor: isDark ? AppColors.darkDeepBg : AppColors.lightBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary)),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: borderColor),
            ),
            onPressed: isExpired
                ? null
                : () => _pickProofImage(ImageSource.gallery),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_proofPath != null ? Icons.check_circle_rounded : Icons.add_photo_alternate_rounded, color: _proofPath != null ? AppColors.income : primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _proofPath != null ? 'Bukti Terpilih: ${_proofPath!.split('/').last}' : 'Lampirkan Bukti Transfer (Opsional)',
                    style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: (isExpired || _isClaiming) ? null : _handleClaimPayment,
            child: _isClaiming
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Saya Sudah Bayar',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
          ),
        ],
      ),
    );
  }
}
