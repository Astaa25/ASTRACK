import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/saas_models.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/payment/payment_models.dart';
import '../../../services/payment/payment_service.dart';
import '../../../services/saas_backend_service.dart';
import '../../../models/coupon_model.dart';
import '../../payment/manual_qris_checkout_screen.dart';
import '../models/astra_feature.dart';

/// Opens the dynamic, modern Upgrade Paywall bottom sheet
Future<bool?> showUpgradePaywall(
  BuildContext context, {
  required AstraFeature feature,
  VoidCallback? onUnlocked,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.65),
    builder: (ctx) => UpgradePaywallSheet(
      feature: feature,
      onUnlocked: onUnlocked,
    ),
  );
}

class UpgradePaywallSheet extends StatefulWidget {
  final AstraFeature feature;
  final VoidCallback? onUnlocked;

  const UpgradePaywallSheet({
    super.key,
    required this.feature,
    this.onUnlocked,
  });

  @override
  State<UpgradePaywallSheet> createState() => _UpgradePaywallSheetState();
}

class _UpgradePaywallSheetState extends State<UpgradePaywallSheet> {
  final _saas = SaaSBackendService();
  bool _isLoadingPlans = true;
  String? _errorMessage;
  bool _isOffline = false;

  List<Plan> _availablePlans = [];
  Plan? _selectedPlan;
  Subscription? _currentSub;
  bool _isProcessingPayment = false;

  final TextEditingController _couponController = TextEditingController();
  CouponValidationResult? _appliedCouponResult;
  bool _isValidatingCoupon = false;
  String? _couponErrorText;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty || _selectedPlan == null) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isValidatingCoupon = true;
      _couponErrorText = null;
    });

    final currentUser = Supabase.instance.client.auth.currentUser;
    final userId = currentUser?.id ?? 'guest_user';

    final result = await _saas.validateCouponServer(
      code: code,
      planId: _selectedPlan!.id,
      userId: userId,
    );

    if (!mounted) return;

    if (result.isValid) {
      HapticFeedback.lightImpact();
      setState(() {
        _appliedCouponResult = result;
        _couponErrorText = null;
        _isValidatingCoupon = false;
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _appliedCouponResult = null;
        _couponErrorText = result.errorMessage ?? 'Kode kupon tidak valid.';
        _isValidatingCoupon = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponResult = null;
      _couponErrorText = null;
      _couponController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPlansAndSubscription();
  }

  Future<void> _loadPlansAndSubscription() async {
    setState(() {
      _isLoadingPlans = true;
      _errorMessage = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = currentUser?.id ?? 'guest_user';

      // 1. Fetch current subscription
      final sub = await _saas.getUserSubscription(userId);

      // 2. Fetch live plans from database
      final plans = await _saas.getPlans();
      final activePaidPlans = plans.where((p) => p.isActive && p.monthlyPrice > 0).toList();

      if (activePaidPlans.isEmpty) {
        setState(() {
          _errorMessage = "Plans couldn't be loaded";
          _isLoadingPlans = false;
        });
        return;
      }

      // Default selection: if feature requires Pro, pre-select Pro; otherwise pre-select recommended or first
      Plan defaultPlan = activePaidPlans.firstWhere(
        (p) => p.id == widget.feature.requiredPlanId,
        orElse: () => activePaidPlans.firstWhere(
          (p) => p.isRecommended,
          orElse: () => activePaidPlans.first,
        ),
      );

      setState(() {
        _currentSub = sub;
        _availablePlans = activePaidPlans;
        _selectedPlan = defaultPlan;
        _isLoadingPlans = false;
      });
    } on SocketException {
      setState(() {
        _isOffline = true;
        _errorMessage = 'Upgrade requires an internet connection.';
        _isLoadingPlans = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Plans couldn't be loaded";
        _isLoadingPlans = false;
      });
    }
  }

  Future<void> _handleUpgrade() async {
    if (_isProcessingPayment || _selectedPlan == null) return;

    final selected = _selectedPlan!;
    final isCurrentActive = _currentSub?.status == SubscriptionStatus.active &&
        _currentSub?.planId == selected.id &&
        _currentSub!.currentPeriodEnd.isAfter(DateTime.now());

    if (isCurrentActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anda sudah memiliki langganan ${selected.name} yang aktif.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isProcessingPayment = true);

    final currentUser = Supabase.instance.client.auth.currentUser;
    final userId = currentUser?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    final userEmail = currentUser?.email ?? 'pengguna@astrack.local';

    // Authoritative Server-side Price & Coupon Re-verification (Anti-Tampering)
    double amountToCharge = selected.monthlyPrice;
    if (_appliedCouponResult != null && _appliedCouponResult!.isValid) {
      final serverCheck = await _saas.validateCouponServer(
        code: _appliedCouponResult!.coupon!.code,
        planId: selected.id,
        userId: userId,
      );
      if (!serverCheck.isValid) {
        if (mounted) {
          setState(() {
            _appliedCouponResult = null;
            _couponErrorText = serverCheck.errorMessage ?? 'Kupon sudah tidak valid.';
            _isProcessingPayment = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(serverCheck.errorMessage ?? 'Kupon sudah tidak valid.'), backgroundColor: AppColors.expense),
          );
        }
        return;
      }
      amountToCharge = serverCheck.finalPrice;
    }

    try {
      final provider = PaymentGatewayFactory.create();
      final order = await provider.createOrder(
        userId: userId,
        planId: selected.id,
        amount: amountToCharge,
        userEmail: userEmail,
        userName: 'Pengguna ASTRACK',
      );

      if (!mounted) return;

      if (provider is ManualQrisPaymentProvider) {
        setState(() => _isProcessingPayment = false);
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ManualQrisCheckoutScreen(order: order, plan: selected),
          ),
        );
        return;
      }

      // If sandbox provider, present realistic payment simulation modal
      if (provider is SandboxPaymentProvider) {
        final paymentConfirmed = await _showSandboxCheckoutModal(order, selected, amountToCharge);
        if (paymentConfirmed == true) {
          // If coupon was applied, redeem it atomically on server
          if (_appliedCouponResult != null && _appliedCouponResult!.isValid) {
            await _saas.redeemCouponOrder(
              code: _appliedCouponResult!.coupon!.code,
              planId: selected.id,
              userId: userId,
              orderId: order.orderId,
            );
          }

          // Record verified subscription server-side with immutable transaction snapshot
          await _saas.recordSuccessfulSubscription(
            userId: userId,
            planId: selected.id,
            durationMonths: selected.durationMonths,
            paidAmount: amountToCharge,
            orderId: order.orderId,
          );

          if (!mounted) return;

          setState(() => _isProcessingPayment = false);
          Navigator.of(context).pop(true);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Selamat! Paket ${selected.name} berhasil diaktifkan.'),
              backgroundColor: AppColors.income,
            ),
          );

          widget.onUnlocked?.call();
          return;
        } else {
          // Canceled or failed
          if (mounted) {
            setState(() => _isProcessingPayment = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Payment wasn't completed"),
                backgroundColor: AppColors.expense,
              ),
            );
          }
          return;
        }
      }

      // For Production Midtrans/Xendit/Stripe
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mengarahkan ke ${provider.providerName}: Order ${order.orderId}'),
          backgroundColor: AppColors.transfer,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment wasn't completed: $e"),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _handleQrisUpgrade() async {
    if (_isProcessingPayment || _selectedPlan == null) return;
    final selected = _selectedPlan!;
    setState(() => _isProcessingPayment = true);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userId = currentUser?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final qrisProvider = ManualQrisPaymentProvider();
      final order = await qrisProvider.createOrder(
        userId: userId,
        planId: selected.id,
        amount: selected.monthlyPrice,
        couponCode: _appliedCouponResult?.coupon?.code,
      );

      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ManualQrisCheckoutScreen(order: order, plan: selected),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat transaksi QRIS: $e'), backgroundColor: AppColors.expense),
      );
    }
  }

  Future<bool?> _showSandboxCheckoutModal(PaymentOrder order, Plan plan, double finalAmount) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = theme.isDarkMode;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payment_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ASTRACK Pay Gateway',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulasi Pembayaran Terverifikasi (Sandbox)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow('Order ID', order.orderId, isDark),
            _infoRow('Paket', '${plan.name} (${plan.durationLabel})', isDark),
            if (_appliedCouponResult != null) ...[
              _infoRow('Harga Normal', CurrencyFormatter.format(plan.monthlyPrice), isDark),
              _infoRow('Kupon ${_appliedCouponResult!.coupon!.code}', '- ${CurrencyFormatter.format(_appliedCouponResult!.discountAmount)}', isDark, isHighlight: true),
            ],
            _infoRow('Total Tagihan', CurrencyFormatter.format(finalAmount), isDark, isHighlight: true),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Text(
                'Setelah verifikasi server berhasil, entitlement dan subscription akan aktif secara real-time.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batalkan', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bayar & Verifikasi', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight
                  ? (isDark ? AppColors.darkLightGreen : AppColors.income)
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final media = MediaQuery.of(context);
    final isTabletOrWeb = media.size.width > 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTabletOrWeb ? 560 : double.infinity,
          maxHeight: media.size.height * 0.92,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle & Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 32),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),

                // Content scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. HERO SECTION
                        _buildHeroSection(isDark),
                        const SizedBox(height: 20),

                        // 2. FEATURE-SPECIFIC BENEFITS
                        _buildBenefitsSection(isDark),
                        const SizedBox(height: 24),

                        // 3. DYNAMIC PLAN CARDS / LOADING / ERROR / OFFLINE
                        Text(
                          'Pilih Paket Langganan',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_isLoadingPlans)
                          _buildPlansSkeleton(isDark)
                        else if (_isOffline)
                          _buildOfflineState(isDark)
                        else if (_errorMessage != null)
                          _buildErrorState(isDark)
                        else ...[
                          _buildPlansList(isDark),
                          const SizedBox(height: 12),
                          _buildCouponSection(isDark),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // 4. DYNAMIC CTA & DISMISS BUTTON
                _buildBottomAction(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkPrimary, const Color(0xFF0F3E30)]
                  : [AppColors.lightPrimary, AppColors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            widget.feature.icon,
            color: isDark ? AppColors.darkLightGreen : Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.feature.heroTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.feature.heroSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedCard : AppColors.lightSoftGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightLightGreen,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: isDark ? AppColors.darkLightGreen : AppColors.lightPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Keunggulan ${widget.feature.title}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkLightGreen : AppColors.lightPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...widget.feature.benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkLightGreen : AppColors.income).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: isDark ? AppColors.darkLightGreen : AppColors.income,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPlansList(bool isDark) {
    return Column(
      children: _availablePlans.map((plan) {
        final isSelected = _selectedPlan?.id == plan.id;
        final isCurrentPlan = _currentSub?.status == SubscriptionStatus.active &&
            _currentSub?.planId == plan.id &&
            _currentSub!.currentPeriodEnd.isAfter(DateTime.now());

        return GestureDetector(
          onTap: () async {
            HapticFeedback.selectionClick();
            setState(() => _selectedPlan = plan);

            // Re-validate applied coupon against new plan if needed
            if (_appliedCouponResult != null) {
              final currentUser = Supabase.instance.client.auth.currentUser;
              final userId = currentUser?.id ?? 'guest_user';
              final reval = await _saas.validateCouponServer(
                code: _couponController.text.trim(),
                planId: plan.id,
                userId: userId,
              );
              if (mounted) {
                setState(() {
                  if (reval.isValid) {
                    _appliedCouponResult = reval;
                    _couponErrorText = null;
                  } else {
                    _appliedCouponResult = null;
                    _couponErrorText = reval.errorMessage;
                  }
                });
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF0F261E) : AppColors.lightLightGreen.withOpacity(0.4))
                  : (isDark ? AppColors.darkElevatedCard : AppColors.lightBg),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.darkLightGreen : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Radio indicator
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? (isDark ? AppColors.darkLightGreen : AppColors.lightPrimary)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppColors.darkLightGreen : AppColors.lightPrimary)
                              : (isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: isDark ? Colors.black : Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Plan name & Recommended badge in Expanded Wrap
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            plan.name.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          if (plan.isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'BEST VALUE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Current plan indicator
                    if (isCurrentPlan)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.income).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.darkPrimary : AppColors.income,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Current Plan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkLightGreen : AppColors.income,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Price and Duration
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      CurrencyFormatter.format(plan.monthlyPrice),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plan.durationLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),

                if (plan.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],

                if (plan.features.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: plan.features.map((f) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 12, color: isDark ? AppColors.darkLightGreen : AppColors.income),
                            const SizedBox(width: 4),
                            Text(
                              f,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        )).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlansSkeleton(bool isDark) {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 14,
                      color: isDark ? AppColors.darkBorder : Colors.grey.withOpacity(0.2),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 140,
                      height: 18,
                      color: isDark ? AppColors.darkBorder : Colors.grey.withOpacity(0.2),
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

  Widget _buildOfflineState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedCard : AppColors.warningBgLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.warning),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 36, color: AppColors.warning),
          const SizedBox(height: 10),
          Text(
            "You're offline",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upgrade requires an internet connection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadPlansAndSubscription,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedCard : AppColors.expenseBgLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.expense),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.expense),
          const SizedBox(height: 10),
          Text(
            "Plans couldn't be loaded",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadPlansAndSubscription,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isDark) {
    final selected = _selectedPlan;
    final isCurrentActive = selected != null &&
        _currentSub?.status == SubscriptionStatus.active &&
        _currentSub?.planId == selected.id &&
        _currentSub!.currentPeriodEnd.isAfter(DateTime.now());

    final double amountToDisplay = _appliedCouponResult?.finalPrice ?? (selected?.monthlyPrice ?? 0.0);

    String buttonText;
    if (_isProcessingPayment) {
      buttonText = 'Processing...';
    } else if (selected == null) {
      buttonText = 'Unavailable';
    } else if (isCurrentActive) {
      buttonText = 'Current Plan';
    } else {
      buttonText = 'Upgrade to ${selected.name} — ${CurrencyFormatter.format(amountToDisplay)}';
    }

    final isButtonEnabled = !_isProcessingPayment && selected != null && !isCurrentActive && !_isOffline;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                foregroundColor: isDark ? Colors.black : Colors.white,
                disabledBackgroundColor: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                disabledForegroundColor: Colors.grey,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: isButtonEnabled ? _handleUpgrade : null,
              child: _isProcessingPayment
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          if (!isCurrentActive && selected != null && !_isOffline) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  side: BorderSide(
                    color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                label: const Text(
                  'Bayar via QRIS Manual (Instan)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                onPressed: isButtonEnabled ? _handleQrisUpgrade : null,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isProcessingPayment ? null : () => Navigator.of(context).pop(false),
            child: Text(
              'Maybe later',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(bool isDark) {
    if (_selectedPlan == null) return const SizedBox.shrink();

    final isApplied = _appliedCouponResult != null && _appliedCouponResult!.isValid;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isApplied
              ? (isDark ? AppColors.darkLightGreen : AppColors.income)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 16,
                color: isDark ? AppColors.darkLightGreen : AppColors.lightPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Punya kode kupon promo?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isApplied) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Contoh: ASTRACK20',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _applyCoupon(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isValidatingCoupon ? null : _applyCoupon,
                    child: _isValidatingCoupon
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          )
                        : const Text('Gunakan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
            if (_couponErrorText != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.expense),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _couponErrorText!,
                      style: const TextStyle(fontSize: 12, color: AppColors.expense, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkLightGreen : AppColors.income).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkLightGreen : AppColors.income,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_appliedCouponResult!.coupon!.code} • ${_appliedCouponResult!.coupon!.discountLabel}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkLightGreen : AppColors.income,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _removeCoupon,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        'Hapus',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _priceBreakdownRow('Harga Normal', CurrencyFormatter.format(_appliedCouponResult!.originalPrice), isDark),
            _priceBreakdownRow('Potongan Kupon', '- ${CurrencyFormatter.format(_appliedCouponResult!.discountAmount)}', isDark, isDiscount: true),
            Divider(height: 16, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            _priceBreakdownRow('Total Tagihan', CurrencyFormatter.format(_appliedCouponResult!.finalPrice), isDark, isTotal: true),
          ],
        ],
      ),
    );
  }

  Widget _priceBreakdownRow(String label, String value, bool isDark, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12.5,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: isTotal
                  ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 15 : 12.5,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: isDiscount
                  ? (isDark ? AppColors.darkLightGreen : AppColors.income)
                  : (isTotal
                      ? (isDark ? AppColors.darkLightGreen : AppColors.income)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
