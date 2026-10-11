import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction_item.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/quick_actions.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/modern_bottom_nav.dart';
import '../../widgets/astrack_logo.dart';
import '../../widgets/tutorial_overlay.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/utils/date_formatter.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import '../ai/ai_chat_screen.dart';
import '../scanner/receipt_scanner_screen.dart';
import '../statistics/statistics_screen.dart';
import '../sources/sources_screen.dart';
import '../budget/budget_screen.dart';
import '../savings/savings_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/responsive/responsive_breakpoints.dart';
import '../../core/responsive/adaptive_container.dart';
import '../subscription/models/astra_feature.dart';
import '../subscription/services/feature_gate_service.dart';
import 'widgets/dashboard_upgrade_card.dart';
import '../profile/profile_screen.dart';
import '../recurring/recurring_screen.dart';
import '../policy/policy_screen.dart';
import '../../services/saas_backend_service.dart';
import '../../services/financial_insight_service.dart';
import '../auth/login_screen.dart';
import '../../services/supabase_auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTabIndex = 0;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final saas = SaaSBackendService();
    final hasAccepted = await saas.hasAcceptedLatestPolicy('current_user_123');
    if (!hasAccepted && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PolicyScreen()));
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final tutorialDone = prefs.getBool('tutorial_done') ?? false;
    if (!tutorialDone && mounted) {
      // Slight delay so dashboard renders first
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _showTutorial = true);
    }
  }

  void _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_done', true);
    if (mounted) setState(() => _showTutorial = false);
  }

  void _openAddSheet(TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(initialType: type),
    );
  }

  void _showCenterActionMenu() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = theme.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aksi Cepat Finansial',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _menuTile(
              ctx: ctx,
              icon: Icons.add_rounded,
              iconBg: AppColors.income.withOpacity(0.15),
              iconColor: AppColors.income,
              title: 'Catat Pemasukan',
              onTap: () => _openAddSheet(TransactionType.income),
            ),
            _menuTile(
              ctx: ctx,
              icon: Icons.remove_rounded,
              iconBg: AppColors.expense.withOpacity(0.15),
              iconColor: AppColors.expense,
              title: 'Catat Pengeluaran',
              onTap: () => _openAddSheet(TransactionType.expense),
            ),
            _menuTile(
              ctx: ctx,
              icon: Icons.swap_horiz_rounded,
              iconBg: AppColors.transfer.withOpacity(0.15),
              iconColor: AppColors.transfer,
              title: 'Transfer Antar Rekening',
              onTap: () => _openAddSheet(TransactionType.transfer),
            ),
            _menuTile(
              ctx: ctx,
              icon: Icons.document_scanner_outlined,
              iconBg: AppColors.saving.withOpacity(0.15),
              iconColor: AppColors.saving,
              title: 'Scan Struk Belanja (OCR)',
              onTap: () {
                Navigator.pop(ctx);
                FeatureGateService.checkAndGate(
                  context,
                  feature: AstraFeatures.receiptScanner,
                  onGranted: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()),
                  ),
                );
              },
            ),
            _menuTile(
              ctx: ctx,
              icon: Icons.psychology_outlined,
              iconBg: AppColors.darkPrimary.withOpacity(0.15),
              iconColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              title: 'ASTRACK Insight — Analisis AI',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AIChatScreen())),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _menuTile({
    required BuildContext ctx,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: () {
        Navigator.of(ctx).pop();
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final isTabletOrDesktop = context.isTabletOrLarger;
    final tabPages = [
      _buildHomeDashboard(context, isDark),
      const TransactionsScreen(),
      const StatisticsScreen(),
      _buildMoreMenu(context, isDark),
    ];

    if (isTabletOrDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              selectedIndex: _currentTabIndex.clamp(0, 3),
              onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const AstrackLogo(size: 38),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onPressed: _showCenterActionMenu,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Catat', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.emerald),
                  label: Text('Overview'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.table_chart_rounded),
                  selectedIcon: Icon(Icons.table_chart_rounded, color: AppColors.emerald),
                  label: Text('Keuangan'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.pie_chart_outline_rounded),
                  selectedIcon: Icon(Icons.pie_chart_rounded, color: AppColors.emerald),
                  label: Text('Statistik'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_rounded),
                  selectedIcon: Icon(Icons.menu_open_rounded, color: AppColors.emerald),
                  label: Text('Lainnya'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _FadeIndexedStack(
                index: _currentTabIndex.clamp(0, 3),
                children: tabPages,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          body: _FadeIndexedStack(
            index: _currentTabIndex.clamp(0, 3),
            children: tabPages,
          ),
          bottomNavigationBar: ModernBottomNav(
            currentIndex: _currentTabIndex,
            isDark: isDark,
            onTabSelected: (idx) => setState(() => _currentTabIndex = idx),
            onCenterFabPressed: _showCenterActionMenu,
          ),
        ),
        if (_showTutorial)
          Positioned.fill(
            child: AppTutorialOverlay(
              steps: kDashboardTutorialSteps,
              onFinished: _dismissTutorial,
            ),
          ),
      ],
    );
  }

  // ─── HOME DASHBOARD ──────────────────────────────────────────────────────────
  Widget _buildHomeDashboard(BuildContext context, bool isDark) {
    final finance = Provider.of<FinanceProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    final recentTransactions = finance.transactions.take(5).toList();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.emerald,
        onRefresh: () async => finance.loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 84),
          child: AdaptiveContainer(
            maxWidth: 900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // ── 1. Top Header ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormatter.getGreeting(
                              finance.profile.name.split(' ').first),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ringkasan finansial Anda saat ini',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                        onPressed: () => theme.toggleTheme(),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                  .withOpacity(0.18),
                          child: Text(
                            finance.profile.name.isNotEmpty
                                ? finance.profile.name[0]
                                : 'A',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── 2. Balance Card ──────────────────────────────────────────
              BalanceCard(
                totalBalance: finance.totalBalance,
                monthlyIncome: finance.monthlyIncome,
                monthlyExpense: finance.monthlyExpense,
                isHidden: finance.hideBalance,
                onToggleHide: finance.toggleHideBalance,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // ── 2b. Saldo per Fund Carousel (Fase 1 Core Ledger) ──────────
              _buildFundsCarousel(context, isDark, finance),

              const SizedBox(height: 14),

              // ── 2c. Safe-to-Spend Daily Indicator (Fase 1 Core Ledger) ────
              _buildSafeToSpendCard(context, isDark, finance),

              const SizedBox(height: 12),

              // ── 2d. Financial Health Score Quick Card (Fase 2 Planning & Insight) ──
              _buildFinancialHealthCard(context, isDark, finance),

              const SizedBox(height: 18),

              // ── 3. Quick Actions ─────────────────────────────────────────
              QuickActionsRow(
                isDark: isDark,
                onIncome: () => _openAddSheet(TransactionType.income),
                onExpense: () => _openAddSheet(TransactionType.expense),
                onTransfer: () => _openAddSheet(TransactionType.transfer),
                onScan: () {
                  FeatureGateService.checkAndGate(
                    context,
                    feature: AstraFeatures.receiptScanner,
                    onGranted: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()),
                    ),
                  );
                },
                onAskAI: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AIChatScreen()));
                },
              ),

              const SizedBox(height: 18),

              // ── 3b. Budget Terkini (Fase 1 Core Ledger) ───────────────────
              _buildBudgetStatusBar(context, isDark, finance),

              const SizedBox(height: 24),

              // ── 4. ASTRACK Insight (AI Feature — HERO) ───────────────────
              _buildInsightCard(context, isDark, finance),

              // ── 4b. Dynamic Non-Intrusive Upgrade Card ───────────────────
              const DashboardUpgradeCard(),

              const SizedBox(height: 24),

              // ── 5. Cashflow Bar Chart ─────────────────────────────────────
              _buildCashflowChart(context, isDark, finance),

              const SizedBox(height: 24),

              // ── 6. Recent Transactions ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Transaksi Terkini',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentTabIndex = 1),
                    child: Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (recentTransactions.isEmpty)
                AppEmptyState(
                  title: 'Belum Ada Transaksi',
                  subtitle: 'Catat pengeluaran atau pemasukan pertamamu agar ASTRACK bisa mulai menganalisis keuanganmu.',
                  icon: Icons.receipt_long_rounded,
                  buttonText: 'Catat Transaksi',
                  onButtonPressed: _showCenterActionMenu,
                )
              else
                ...recentTransactions.map((tx) {
                  return TransactionTile(
                    item: tx,
                    isDark: isDark,
                    onDelete: () => finance.deleteTransaction(tx.id),
                  );
                }),

              const SizedBox(height: 24),
            ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFundSourceIcon(String iconName) {
    switch (iconName) {
      case 'piggy_bank':
        return Icons.savings_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'smartphone':
      case 'phone_android':
        return Icons.phone_android_rounded;
      case 'account_balance':
        return Icons.account_balance_rounded;
      case 'wallet':
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Widget _buildFundsCarousel(BuildContext context, bool isDark, FinanceProvider finance) {
    final sources = finance.sources;
    final primaryAccent = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Sumber Dana',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sources.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SourcesScreen()),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Kelola',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primaryAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sources.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final s = sources[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() => _currentTabIndex = 1);
                },
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: s.isDefault
                          ? primaryAccent.withOpacity(0.5)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: s.isDefault ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getFundSourceIcon(s.iconName),
                            size: 16,
                            color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (s.isDefault)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: primaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        finance.hideBalance ? 'Rp ••••••' : CurrencyFormatter.format(s.balance),
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: s.balance >= 0
                              ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                              : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSafeToSpendCard(BuildContext context, bool isDark, FinanceProvider finance) {
    final safeDaily = finance.safeToSpendDaily;
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (lastDay - now.day + 1).clamp(1, 31);
    final primaryAccent = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryAccent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_outlined,
              size: 20,
              color: primaryAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Aman Dibelanjakan Hari Ini',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sisa $remainingDays hari',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  finance.hideBalance ? 'Rp •••••• / hari' : '${CurrencyFormatter.format(safeDaily)} / hari',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: safeDaily > 0 ? primaryAccent : AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard(BuildContext context, bool isDark, FinanceProvider finance) {
    final healthScore = finance.financialHealthScore;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _currentTabIndex = 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: healthScore.grade.color.withAlpha(20),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: healthScore.grade.color.withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: healthScore.grade.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  healthScore.grade.gradeLetter,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kesehatan Finansial: ${healthScore.overallScore}/100 • ${healthScore.grade.label}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pilar: Saving ${(healthScore.actualSavingsRate * 100).toInt()}% • Buffer ${healthScore.emergencyBufferMonths} bln',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: healthScore.grade.color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStatusBar(BuildContext context, bool isDark, FinanceProvider finance) {
    if (finance.budgets.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final thisMonthBudgets = finance.budgets.where((b) => b.month == now.month && b.year == now.year).toList();
    if (thisMonthBudgets.isEmpty) return const SizedBox.shrink();

    final totalLimit = thisMonthBudgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    final totalSpent = thisMonthBudgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    final percent = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final isOverbudget = totalSpent > totalLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Budget Terkini',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Kelola',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Terpakai ${CurrencyFormatter.format(totalSpent)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOverbudget ? AppColors.expense : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Limit ${CurrencyFormatter.format(totalLimit)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 7,
                  backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverbudget
                        ? AppColors.expense
                        : (percent > 0.8
                            ? const Color(0xFFF59E0B)
                            : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── ASTRACK INSIGHT CARD (AI Hero) ──────────────────────────────────────────
  Widget _buildInsightCard(
      BuildContext context, bool isDark, FinanceProvider finance) {
    final ratio = finance.monthlyIncome > 0
        ? finance.monthlyExpense / finance.monthlyIncome
        : 0.0;
    final savingsRate = ((1 - ratio) * 100).clamp(0, 100).toStringAsFixed(0);
    final isHealthy = ratio < 0.8;

    final generatedInsights = FinancialInsightService.generateInsights(
      transactions: finance.transactions,
      budgets: finance.budgets,
    );

    String insightTitle = 'ASTRACK Smart Insight';
    String insight;

    if (generatedInsights.isNotEmpty) {
      final topInsight = generatedInsights.first;
      insightTitle = topInsight.title;
      insight = topInsight.description;
    } else {
      if (finance.transactions.isEmpty) {
        insight =
            'Mulai catat transaksi pertama Anda. ASTRACK Insight akan menganalisis pola keuangan dan memberi rekomendasi personal.';
      } else if (ratio == 0) {
        insight =
            'Anda memiliki pemasukan bulan ini. Segera catat pengeluaran agar ASTRACK bisa memberi analisis akurat.';
      } else if (isHealthy) {
        insight =
            'Keuangan Anda sehat! Tingkat tabungan bulan ini mencapai $savingsRate%. Pertahankan pola ini dan pertimbangkan untuk mengalokasikan surplus ke target tabungan.';
      } else {
        insight =
            'Pengeluaran Anda mendekati batas pemasukan (${(ratio * 100).toStringAsFixed(0)}%). Tinjau anggaran kategori dan pangkas pengeluaran non-esensial untuk menjaga kesehatan finansial.';
      }
    }

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AIChatScreen())),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0E2A1E), Color(0xFF081510)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.lightPrimary.withOpacity(0.06),
                    AppColors.lightPrimary.withOpacity(0.02),
                  ],
                ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightPrimary.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: AppColors.darkPrimary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  BoxShadow(
                    color: AppColors.lightPrimary.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Stack(
          children: [
            // Background decorative icon
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.psychology_outlined,
                size: 90,
                color: isDark
                    ? AppColors.darkPrimary.withOpacity(0.08)
                    : AppColors.lightPrimary.withOpacity(0.07),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badge
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimary.withOpacity(0.18)
                              : AppColors.lightPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkPrimary.withOpacity(0.4)
                                : AppColors.lightPrimary.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                insightTitle.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Health indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isHealthy
                              ? AppColors.income.withOpacity(0.12)
                              : AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isHealthy
                                  ? Icons.trending_up_rounded
                                  : Icons.warning_amber_rounded,
                              size: 13,
                              color: isHealthy
                                  ? AppColors.income
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isHealthy ? 'Sehat' : 'Perhatikan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isHealthy
                                    ? AppColors.income
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // AI Insight text
                  Text(
                    insight,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  if (finance.monthlyIncome > 0)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        _insightStat(
                          label: 'Tabungan',
                          value: '$savingsRate%',
                          color: isHealthy
                              ? AppColors.income
                              : AppColors.warning,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 16),
                        _insightStat(
                          label: 'Pengeluaran',
                          value:
                              '${(ratio * 100).toStringAsFixed(0)}%',
                          color: ratio > 0.8
                              ? AppColors.expense
                              : AppColors.lightTextSecondary,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    // CTA
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 5),
                              const Text(
                                'Tanya Detail',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 13, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'Mulai Analisis',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightStat({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  // ─── CASHFLOW CHART ───────────────────────────────────────────────────────────
  Widget _buildCashflowChart(
      BuildContext context, bool isDark, FinanceProvider finance) {
    // Build last 6 months labels and values
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - (5 - i));
      return date;
    });

    final incomeByMonth = <int, double>{};
    final expenseByMonth = <int, double>{};

    for (final tx in finance.transactions) {
      final key = tx.dateTime.year * 100 + tx.dateTime.month;
      if (tx.type == TransactionType.income) {
        incomeByMonth[key] = (incomeByMonth[key] ?? 0) + tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expenseByMonth[key] = (expenseByMonth[key] ?? 0) + tx.amount;
      }
    }

    final maxVal = months.fold<double>(1000, (prev, m) {
      final key = m.year * 100 + m.month;
      return [
        prev,
        incomeByMonth[key] ?? 0,
        expenseByMonth[key] ?? 0,
      ].reduce((a, b) => a > b ? a : b);
    });

    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Arus Kas 6 Bulan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              // Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legend('Masuk', AppColors.income, isDark),
                  const SizedBox(width: 12),
                  _legend('Keluar', AppColors.expense, isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: months.map((m) {
                final key = m.year * 100 + m.month;
                final inc = incomeByMonth[key] ?? 0;
                final exp = expenseByMonth[key] ?? 0;
                final incH = maxVal > 0 ? (inc / maxVal * 110).clamp(4.0, 110.0) : 4.0;
                final expH = maxVal > 0 ? (exp / maxVal * 110).clamp(4.0, 110.0) : 4.0;
                final isCurrentMonth =
                    m.year == now.year && m.month == now.month;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Income bar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _bar(incH, AppColors.income, isDark,
                                isCurrentMonth),
                            const SizedBox(width: 2),
                            _bar(expH, AppColors.expense, isDark,
                                isCurrentMonth),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          monthNames[m.month - 1],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isCurrentMonth
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isCurrentMonth
                                ? (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary)
                                : (isDark
                                    ? AppColors.darkMuted
                                    : AppColors.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double height, Color color, bool isDark, bool highlight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: 12,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(highlight ? 1.0 : 0.55),
        borderRadius: BorderRadius.circular(6),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
    );
  }

  Widget _legend(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  // ─── MORE MENU ────────────────────────────────────────────────────────────────
  Widget _buildMoreMenu(BuildContext context, bool isDark) {
    final finance = Provider.of<FinanceProvider>(context);
    final profile = finance.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu & Fitur Lainnya',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // ─── Profile Header ───────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withAlpha(30),
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.lightTextPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    icon: const Icon(Icons.edit_outlined),
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    tooltip: 'Edit Profil',
                  ),
                ],
              ),
            ),

            _buildMenuItem(
              title: 'Riwayat Transaksi',
              subtitle: 'Daftar transaksi kronologis lengkap',
              icon: Icons.receipt_long_rounded,
              isDark: isDark,
              onTap: () => setState(() => _currentTabIndex = 1),
            ),
            _buildMenuItem(
              title: 'Sumber Dana (Accounts)',
              subtitle: 'Kelola dompet, rekening bank & e-wallet',
              icon: Icons.account_balance_wallet_outlined,
              isDark: isDark,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SourcesScreen())),
            ),
            _buildMenuItem(
              title: 'Anggaran Belanja (Budgets)',
              subtitle: 'Pasang batas pengeluaran bulanan kategori',
              icon: Icons.pie_chart_outline_rounded,
              isDark: isDark,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const BudgetScreen())),
            ),
            _buildMenuItem(
              title: 'Tagihan Rutin & Langganan',
              subtitle: 'Catat otomatis WiFi, kuota, & tagihan tetap bulanan',
              icon: Icons.event_repeat_rounded,
              isDark: isDark,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const RecurringScreen())),
            ),
            _buildMenuItem(
              title: 'Target Tabungan (Savings)',
              subtitle: 'Impian masa depan & dana darurat',
              icon: Icons.savings_outlined,
              isDark: isDark,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SavingsScreen())),
            ),
            _buildMenuItem(
              title: 'Laporan & Ekspor Data',
              subtitle: 'Ekspor CSV spreadsheet & cadangan JSON',
              icon: Icons.description_outlined,
              isDark: isDark,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
            ),
            _buildMenuItem(
              title: 'Pengaturan (Settings)',
              subtitle: 'Tema, privasi saldo, dan konfigurasi',
              icon: Icons.settings_outlined,
              isDark: isDark,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),

            const SizedBox(height: 24),
            // ─── Logout Button ────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, finance),
              icon: const Icon(Icons.logout_rounded, color: AppColors.expense),
              label: const Text('Keluar dari Akun', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.expense, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 84),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari sesi akun ini?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseAuthService.signOut();
              finance.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                .withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              size: 22),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkMuted
                    : AppColors.lightTextSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    ),
    );
  }
}

/// Smooth fade transition wrapper for IndexedStack to ensure buttery tab switching
class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _FadeIndexedStack({
    required this.index,
    required this.children,
  });

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..forward();
  }

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}

