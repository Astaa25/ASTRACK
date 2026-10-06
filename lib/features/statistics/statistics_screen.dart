import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction_item.dart';
import '../../models/financial_health_score.dart';
import '../../core/utils/currency_formatter.dart';
import 'package:flutter/services.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'Bulan Ini';
  DateTimeRange? _customDateRange;
  int _touchedPieIndex = -1;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TransactionItem> _getFiltered(List<TransactionItem> all) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_selectedPeriod == 'Kustom' && _customDateRange != null) {
      start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
      end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
      return all.where((t) => t.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) && t.dateTime.isBefore(end.add(const Duration(seconds: 1)))).toList();
    }

    switch (_selectedPeriod) {
      case 'Hari Ini':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Minggu Ini':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'Tahun Ini':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      default:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }
    return all.where((t) => t.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) && t.dateTime.isBefore(end.add(const Duration(seconds: 1)))).toList();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 14)),
        end: now,
      ),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'Kustom';
      });
    }
  }

  final List<Color> _catColors = [
    const Color(0xFF22C55E), const Color(0xFFEF4444), const Color(0xFF3B82F6),
    const Color(0xFFF59E0B), const Color(0xFF0D9488), const Color(0xFF8B5CF6),
    const Color(0xFFEC4899), const Color(0xFF06B6D4), const Color(0xFF84CC16),
    const Color(0xFFF97316),
  ];

  Color _catColor(int i) => _catColors[i % _catColors.length];

  String _compact(double v) {
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}M';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }

  List<_MonthData> _monthlyData(List<TransactionItem> all) {
    final now = DateTime.now();
    final names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return List.generate(6, (i) {
      int m = now.month - (5 - i);
      int y = now.year;
      if (m <= 0) { m += 12; y -= 1; }
      final s = DateTime(y, m, 1);
      final e = DateTime(y, m + 1, 0, 23, 59, 59);
      final tx = all.where((t) => t.dateTime.isAfter(s) && t.dateTime.isBefore(e)).toList();
      final inc = tx.where((t) => t.type == TransactionType.income).fold<double>(0, (a, b) => a + b.amount);
      final exp = tx.where((t) => t.type == TransactionType.expense).fold<double>(0, (a, b) => a + b.amount);
      return _MonthData(names[m], inc, exp);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final isDark = theme.isDarkMode;
    final filtered = _getFiltered(finance.transactions);
    final income = filtered.where((t) => t.type == TransactionType.income).fold<double>(0, (a, b) => a + b.amount);
    final expense = filtered.where((t) => t.type == TransactionType.expense).fold<double>(0, (a, b) => a + b.amount);
    final net = income - expense;
    final catMap = <String, double>{};
    for (final tx in filtered) {
      if (tx.type == TransactionType.expense) catMap[tx.categoryName] = (catMap[tx.categoryName] ?? 0) + tx.amount;
    }
    final cats = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final mData = _monthlyData(finance.transactions);
    final maxY = mData.isEmpty ? 1000000.0 : mData.map((m) => m.income > m.expense ? m.income : m.expense).reduce((a, b) => a > b ? a : b);

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final healthScore = finance.financialHealthScore;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkDeepBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        title: Text(
          'Statistik & Analisis',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: primary.withAlpha(25),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          labelColor: primary,
          unselectedLabelColor: textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Tren 6 Bulan'),
            Tab(text: 'Skor Kesehatan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _summaryTab(isDark, income, expense, net, cats, filtered, primary, cardColor, border, textPrimary, textSecondary, healthScore),
          _trendTab(isDark, mData, maxY, primary, cardColor, border, textPrimary, textSecondary),
          _healthTab(isDark, healthScore, primary, cardColor, border, textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _summaryTab(
    bool isDark,
    double income,
    double expense,
    double net,
    List<MapEntry<String, double>> cats,
    List<TransactionItem> filteredTxs,
    Color primary,
    Color cardColor,
    Color border,
    Color textPrimary,
    Color textSecondary,
    FinancialHealthScore healthScore,
  ) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Period chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'].map((p) {
                  final sel = _selectedPeriod == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedPeriod = p);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? primary : cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: sel ? primary : border),
                          boxShadow: sel ? [BoxShadow(color: primary.withAlpha(50), blurRadius: 8, offset: const Offset(0, 3))] : null,
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Custom Range Chip
                GestureDetector(
                  onTap: _pickCustomRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == 'Kustom' ? primary : cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _selectedPeriod == 'Kustom' ? primary : border),
                      boxShadow: _selectedPeriod == 'Kustom' ? [BoxShadow(color: primary.withAlpha(50), blurRadius: 8, offset: const Offset(0, 3))] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 14,
                          color: _selectedPeriod == 'Kustom' ? Colors.white : textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedPeriod == 'Kustom' && _customDateRange != null
                              ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
                              : 'Kustom...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _selectedPeriod == 'Kustom' ? Colors.white : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Mini Financial Health Banner linking to Tab 3
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _tabController.animateTo(2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: healthScore.grade.color.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: healthScore.grade.color.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Skor Finansial: ${healthScore.overallScore}/100',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                              const SizedBox(width: 6),
                              Text('• ${healthScore.grade.label}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: healthScore.grade.color)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lihat analisis 4 pilar kesehatan keuangan Anda →',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: healthScore.grade.color, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Net Cash Flow Card ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: net >= 0
                    ? [const Color(0xFF059669), const Color(0xFF0EA5E9)]
                    : [const Color(0xFFEF4444), const Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (net >= 0 ? const Color(0xFF059669) : const Color(0xFFEF4444)).withAlpha(70),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Arus Kas Bersih', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: net),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    CurrencyFormatter.format(value),
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: income),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => _gradientMetric('↑ Masuk', CurrencyFormatter.format(value), Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: expense),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => _gradientMetric('↓ Keluar', CurrencyFormatter.format(value), Colors.white),
                  ),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // ─── Modern Bar/Line Chart: Income vs Expense ─────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text('Pemasukan vs Pengeluaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legDot(const Color(0xFF22C55E), 'Masuk', textSecondary),
                        const SizedBox(width: 12),
                        _legDot(const Color(0xFFEF4444), 'Keluar', textSecondary),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    if (filteredTxs.isEmpty) {
                      return const SizedBox(
                        height: 180,
                        child: Center(child: Text('Belum ada transaksi di periode ini', style: TextStyle(color: Colors.grey))),
                      );
                    }

                    int bucketCount = 7;
                    DateTime startDate = DateTime.now();
                    Duration step = const Duration(days: 1);

                    final now = DateTime.now();
                    if (_selectedPeriod == 'Hari Ini') {
                      bucketCount = 24;
                      startDate = DateTime(now.year, now.month, now.day);
                      step = const Duration(hours: 1);
                    } else if (_selectedPeriod == 'Minggu Ini') {
                      bucketCount = 7;
                      startDate = now.subtract(Duration(days: now.weekday - 1));
                      startDate = DateTime(startDate.year, startDate.month, startDate.day);
                      step = const Duration(days: 1);
                    } else if (_selectedPeriod == 'Bulan Ini') {
                      bucketCount = DateTime(now.year, now.month + 1, 0).day;
                      startDate = DateTime(now.year, now.month, 1);
                      step = const Duration(days: 1);
                    } else if (_selectedPeriod == 'Tahun Ini') {
                      bucketCount = 12;
                      startDate = DateTime(now.year, 1, 1);
                    } else if (_selectedPeriod == 'Kustom' && _customDateRange != null) {
                      final diff = _customDateRange!.end.difference(_customDateRange!.start).inDays + 1;
                      bucketCount = diff.clamp(1, 31);
                      startDate = _customDateRange!.start;
                      step = const Duration(days: 1);
                    }

                    List<FlSpot> incSpots = [];
                    List<FlSpot> expSpots = [];
                    double chartMaxY = 0;

                    for (int i = 0; i < bucketCount; i++) {
                      DateTime bStart;
                      DateTime bEnd;
                      if (_selectedPeriod == 'Tahun Ini') {
                        bStart = DateTime(startDate.year, startDate.month + i, 1);
                        bEnd = DateTime(startDate.year, startDate.month + i + 1, 0, 23, 59, 59);
                      } else {
                        bStart = startDate.add(step * i);
                        bEnd = bStart.add(step).subtract(const Duration(milliseconds: 1));
                      }

                      final txs = filteredTxs.where((t) => t.dateTime.isAfter(bStart.subtract(const Duration(milliseconds: 1))) && t.dateTime.isBefore(bEnd.add(const Duration(milliseconds: 1))));
                      final dInc = txs.where((t) => t.type == TransactionType.income).fold(0.0, (a, b) => a + b.amount);
                      final dExp = txs.where((t) => t.type == TransactionType.expense).fold(0.0, (a, b) => a + b.amount);

                      incSpots.add(FlSpot(i.toDouble(), dInc));
                      expSpots.add(FlSpot(i.toDouble(), dExp));

                      if (dInc > chartMaxY) chartMaxY = dInc;
                      if (dExp > chartMaxY) chartMaxY = dExp;
                    }

                    if (chartMaxY == 0) chartMaxY = 1000;

                    return SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: chartMaxY / 4,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: border.withAlpha(80),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                getTitlesWidget: (value, meta) {
                                  final intValue = value.toInt();
                                  if (intValue < 0 || intValue >= bucketCount) return const SizedBox.shrink();

                                  int interval = 1;
                                  if (_selectedPeriod == 'Hari Ini') interval = 4;
                                  else if (_selectedPeriod == 'Bulan Ini' || bucketCount > 14) interval = 5;

                                  if (intValue % interval != 0 && intValue != bucketCount - 1) return const SizedBox.shrink();

                                  String text = '';
                                  if (_selectedPeriod == 'Hari Ini') {
                                    text = '$intValue:00';
                                  } else if (_selectedPeriod == 'Minggu Ini') {
                                    text = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'][intValue % 7];
                                  } else if (_selectedPeriod == 'Bulan Ini') {
                                    text = '${intValue + 1}';
                                  } else if (_selectedPeriod == 'Tahun Ini') {
                                    text = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'][intValue % 12];
                                  } else {
                                    text = '${startDate.add(step * intValue).day}/${startDate.add(step * intValue).month}';
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(text, style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (bucketCount - 1).toDouble(),
                          minY: 0,
                          maxY: chartMaxY * 1.25,
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => isDark ? const Color(0xFF1E293B) : Colors.white,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((LineBarSpot touchedSpot) {
                                  final isInc = touchedSpot.barIndex == 0;
                                  return LineTooltipItem(
                                    CurrencyFormatter.format(touchedSpot.y),
                                    TextStyle(
                                      color: isInc ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: incSpots,
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: const Color(0xFF22C55E),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF22C55E).withAlpha(30),
                              ),
                            ),
                            LineChartBarData(
                              spots: expSpots,
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: const Color(0xFFEF4444),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFFEF4444).withAlpha(30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Donut Chart: Category Breakdown ─────────────────────────────
          if (cats.isNotEmpty) ...[
            Text('Alokasi Pengeluaran per Kategori',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        pieTouchData: PieTouchData(touchCallback: (ev, resp) => setState(() {
                          _touchedPieIndex = (!ev.isInterestedForInteractions || resp == null || resp.touchedSection == null)
                              ? -1 : resp.touchedSection!.touchedSectionIndex;
                        })),
                        sections: cats.asMap().entries.map((e) {
                          final touched = e.key == _touchedPieIndex;
                          final pct = expense > 0 ? e.value.value / expense * 100 : 0.0;
                          return PieChartSectionData(
                            color: _catColor(e.key),
                            value: e.value.value,
                            title: pct > 6 ? '${pct.toStringAsFixed(0)}%' : '',
                            radius: touched ? 74 : 60,
                            titleStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 48,
                        sectionsSpace: 2,
                      )),
                      // Center label
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _touchedPieIndex >= 0 && _touchedPieIndex < cats.length
                                ? '${(cats[_touchedPieIndex].value / expense * 100).toStringAsFixed(1)}%'
                                : '${cats.length}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary),
                          ),
                          Text(
                            _touchedPieIndex >= 0 && _touchedPieIndex < cats.length
                                ? cats[_touchedPieIndex].key
                                : 'Kategori',
                            style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Wrap(
                  spacing: 10, runSpacing: 8,
                  children: cats.asMap().entries.map((e) => GestureDetector(
                    onTap: () => setState(() => _touchedPieIndex = _touchedPieIndex == e.key ? -1 : e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _touchedPieIndex == e.key ? _catColor(e.key).withAlpha(20) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _touchedPieIndex == e.key ? _catColor(e.key) : Colors.transparent,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: _catColor(e.key), shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(e.value.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
                      ]),
                    ),
                  )).toList(),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // Category progress bars
            ...cats.asMap().entries.map((e) {
              final tot = expense > 0 ? expense : 1.0;
              final pct = ((e.value.value / tot) * 100).clamp(0, 100);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _touchedPieIndex == e.key
                      ? _catColor(e.key).withAlpha(12)
                      : cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _touchedPieIndex == e.key ? _catColor(e.key).withAlpha(80) : border,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _catColor(e.key).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(
                      '${pct.toInt()}%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _catColor(e.key)),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(e.value.key, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary))),
                      Text(CurrencyFormatter.format(e.value.value),
                          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 13, color: _catColor(e.key))),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: e.value.value / tot,
                        minHeight: 7,
                        backgroundColor: isDark ? AppColors.darkElevatedCard : const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation<Color>(_catColor(e.key)),
                      ),
                    ),
                  ])),
                ]),
              );
            }),
          ] else
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Center(child: Column(children: [
                Icon(Icons.pie_chart_outline_rounded, size: 48, color: border),
                const SizedBox(height: 12),
                Text('Belum ada pengeluaran pada periode ini.',
                    textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 13)),
              ])),
            ),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _trendTab(bool isDark, List<_MonthData> mData, double maxY, Color primary,
      Color cardColor, Color border, Color textPrimary, Color textSecondary) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tren 6 Bulan Terakhir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
          const SizedBox(height: 4),
          Text('Pemasukan vs Pengeluaran bulanan',
              style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              Row(children: [
                _legDot(const Color(0xFF22C55E), 'Pemasukan', textSecondary),
                const SizedBox(width: 16),
                _legDot(const Color(0xFFEF4444), 'Pengeluaran', textSecondary),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: LineChart(LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: border.withAlpha(80),
                      strokeWidth: 1,
                      dashArray: [6, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (v, _) => v == 0
                            ? const SizedBox.shrink()
                            : Text(_compact(v),
                                style: TextStyle(fontSize: 9, color: textSecondary)),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= mData.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(mData[i].label,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSecondary)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => isDark ? AppColors.darkElevatedCard : Colors.white,
                      getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                        CurrencyFormatter.format(s.y),
                        TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: s.barIndex == 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        ),
                      )).toList(),
                    ),
                  ),
                  minX: 0, maxX: (mData.length - 1).toDouble(), minY: 0, maxY: maxY * 1.25,
                  lineBarsData: [
                    LineChartBarData(
                      spots: mData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.income)).toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFF22C55E),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF22C55E),
                          strokeWidth: 2,
                          strokeColor: isDark ? AppColors.darkCard : Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [const Color(0xFF22C55E).withAlpha(50), const Color(0xFF22C55E).withAlpha(0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: mData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.expense)).toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFFEF4444),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFFEF4444),
                          strokeWidth: 2,
                          strokeColor: isDark ? AppColors.darkCard : Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [const Color(0xFFEF4444).withAlpha(50), const Color(0xFFEF4444).withAlpha(0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                )),
              ),
            ]),
          ),

          const SizedBox(height: 24),
          Text('Ringkasan per Bulan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
          const SizedBox(height: 12),

          ...mData.reversed.map((m) {
            final net = m.income - m.expense;
            final netColor = net >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
            final savingsRate = m.income > 0 ? ((net / m.income) * 100).clamp(-100, 100) : 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: net >= 0
                            ? [const Color(0xFF22C55E).withAlpha(30), const Color(0xFF4ADE80).withAlpha(15)]
                            : [const Color(0xFFEF4444).withAlpha(30), const Color(0xFFF87171).withAlpha(15)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.label,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: netColor)),
                  ),
                  const Spacer(),
                  Text(
                    '${net >= 0 ? '+' : ''}${CurrencyFormatter.format(net)}',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.w800, color: netColor),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _miniStat('Masuk', CurrencyFormatter.format(m.income), const Color(0xFF22C55E))),
                  const SizedBox(width: 8),
                  Expanded(child: _miniStat('Keluar', CurrencyFormatter.format(m.expense), const Color(0xFFEF4444))),
                  const SizedBox(width: 8),
                  Expanded(child: _miniStat(
                    'Rate',
                    '${savingsRate.toStringAsFixed(0)}%',
                    savingsRate >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  )),
                ]),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _healthTab(
    bool isDark,
    FinancialHealthScore score,
    Color primary,
    Color cardColor,
    Color border,
    Color textPrimary,
    Color textSecondary,
  ) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Score Gauge Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F1E19), const Color(0xFF132A22)]
                      : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: score.grade.color.withAlpha(80)),
                boxShadow: [
                  BoxShadow(
                    color: score.grade.color.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Circular Score Badge
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkCard : Colors.white,
                      border: Border.all(color: score.grade.color, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: score.grade.color.withAlpha(50),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${score.overallScore}',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: score.grade.color,
                            ),
                          ),
                          Text(
                            'DARI 100',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: score.grade.color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Grade ${score.grade.gradeLetter}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                score.grade.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Evaluasi komprehensif 4 pilar finansial berbasis saldo ledger, disiplin anggaran, dan cadangan likuid.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── 4 Pillars Breakdown ──────────────────────────────────────────
            Text('4 Pilar Penilaian Finansial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
            const SizedBox(height: 12),

            _pillarCard(
              title: '1. Rasio Tabungan (Savings Rate)',
              subtitle: 'Realisasi: ${(score.actualSavingsRate * 100).toStringAsFixed(0)}% dari pemasukan',
              scoreValue: score.savingsRateScore,
              maxScore: 35.0,
              icon: Icons.savings_rounded,
              color: const Color(0xFF10B981),
              cardColor: cardColor,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _pillarCard(
              title: '2. Disiplin Anggaran (Budget Adherence)',
              subtitle: 'Realisasi utilitas: ${(score.budgetUtilizationRate * 100).toStringAsFixed(0)}% terpakai',
              scoreValue: score.budgetAdherenceScore,
              maxScore: 30.0,
              icon: Icons.pie_chart_rounded,
              color: const Color(0xFF3B82F6),
              cardColor: cardColor,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _pillarCard(
              title: '3. Cadangan Dana Darurat (Emergency Buffer)',
              subtitle: 'Realisasi: ${score.emergencyBufferMonths} bulan pengeluaran aman',
              scoreValue: score.emergencyBufferScore,
              maxScore: 20.0,
              icon: Icons.shield_rounded,
              color: const Color(0xFFF59E0B),
              cardColor: cardColor,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _pillarCard(
              title: '4. Keteraturan Pencatatan (Recording Habit)',
              subtitle: 'Realisasi: ${score.activeRecordingDays} hari aktif dalam 30 hari',
              scoreValue: score.recordingRegularityScore,
              maxScore: 15.0,
              icon: Icons.calendar_today_rounded,
              color: const Color(0xFF8B5CF6),
              cardColor: cardColor,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // ─── Tailored Actionable Recommendations ─────────────────────────
            Text('Rekomendasi Tindakan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: score.recommendations.map((rec) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_forward_rounded, color: primary, size: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            rec,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillarCard({
    required String title,
    required String subtitle,
    required double scoreValue,
    required double maxScore,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final ratio = (scoreValue / maxScore).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: textSecondary)),
                  ],
                ),
              ),
              Text(
                '${scoreValue.toStringAsFixed(1)} / ${maxScore.toInt()}',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: isDark ? AppColors.darkElevatedCard : const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: color.withAlpha(180)), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis),
    ]);
  }

  Widget _legDot(Color color, String label, Color textColor) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28, height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
    ]);
  }
}

class _MonthData {
  final String label;
  final double income;
  final double expense;
  const _MonthData(this.label, this.income, this.expense);
}
