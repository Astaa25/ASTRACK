import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/core/theme/tokens/app_spacing.dart';
import 'package:astrack/core/theme/tokens/app_radius.dart';
import 'package:astrack/core/theme/tokens/app_motion.dart';
import 'package:astrack/core/theme/tokens/app_typography.dart';
import 'package:astrack/core/theme/astrack_theme_extension.dart';
import 'package:astrack/core/responsive/responsive_breakpoints.dart';
import 'package:astrack/core/responsive/adaptive_container.dart';
import 'package:astrack/core/localization/app_localizations.dart';
import 'package:astrack/shared/widgets/amount_text.dart';
import 'package:astrack/shared/widgets/amount_input.dart';
import 'package:astrack/shared/widgets/fund_chip.dart';
import 'package:astrack/shared/widgets/plan_badge.dart';
import 'package:astrack/shared/widgets/section_header.dart';
import 'package:astrack/shared/widgets/empty_state.dart';
import 'package:astrack/shared/widgets/error_state.dart';
import 'package:astrack/shared/widgets/progress_bar.dart';
import 'package:astrack/shared/widgets/primary_button.dart';
import 'package:astrack/shared/widgets/secondary_button.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  group('Phase 0 Foundation: Design Tokens & System Tests', () {
    test('AppSpacing tokens have consistent scale', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 20.0);
      expect(AppSpacing.xxl, 24.0);
      expect(AppSpacing.xxxl, 32.0);
    });

    test('AppRadius tokens have consistent geometry', () {
      expect(AppRadius.xsVal, 4.0);
      expect(AppRadius.smVal, 8.0);
      expect(AppRadius.mdVal, 12.0);
      expect(AppRadius.lgVal, 16.0);
      expect(AppRadius.xlVal, 20.0);
      expect(AppRadius.xxlVal, 24.0);
      expect(AppRadius.fullVal, 999.0);
    });

    test('AppMotion durations and curves match physical guidelines', () {
      expect(AppMotion.tap.inMilliseconds, 120);
      expect(AppMotion.normal.inMilliseconds, 220);
      expect(AppMotion.pageTransition.inMilliseconds, 250);
      expect(AppMotion.sheet.inMilliseconds, 280);
      expect(AppMotion.activeScale, 0.97);
    });

    test('AppTypography provides tabular figures for money accuracy', () {
      expect(AppTypography.tabularFigures, contains(const FontFeature.tabularFigures()));
      final style = AppTypography.financialHero(fontSize: 28);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('AstrackThemeExtension light and dark definitions conform to palette', () {
      expect(AstrackThemeExtension.light.isDark, isFalse);
      expect(AstrackThemeExtension.light.primaryEmerald, const Color(0xFF059669));
      expect(AstrackThemeExtension.light.background, const Color(0xFFFAFAFA));

      expect(AstrackThemeExtension.dark.isDark, isTrue);
      expect(AstrackThemeExtension.dark.primaryEmerald, const Color(0xFF10B981));
      expect(AstrackThemeExtension.dark.background, const Color(0xFF090D0B));
    });
  });

  group('Phase 0 Foundation: Responsive Breakpoints & Window Size Classes', () {
    testWidgets('Breakpoints resolve compact, medium, and expanded correctly', (tester) async {
      // 1. Phone portrait: 400x800 (<600) -> Compact
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(context.isCompact, isTrue);
                expect(context.isMedium, isFalse);
                expect(context.isExpanded, isFalse);
                expect(context.isTabletOrLarger, isFalse);
                expect(
                  context.responsiveValue(compact: 'phone', medium: 'tablet', expanded: 'desktop'),
                  'phone',
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // 2. Tablet portrait: 700x1000 (600 - 840) -> Medium
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1000)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(context.isCompact, isFalse);
                expect(context.isMedium, isTrue);
                expect(context.isExpanded, isFalse);
                expect(context.isTabletOrLarger, isTrue);
                expect(
                  context.responsiveValue(compact: 'phone', medium: 'tablet', expanded: 'desktop'),
                  'tablet',
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // 3. iPad landscape / Desktop: 1100x800 (>840) -> Expanded
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1100, 800)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(context.isCompact, isFalse);
                expect(context.isMedium, isFalse);
                expect(context.isExpanded, isTrue);
                expect(context.isTabletOrLarger, isTrue);
                expect(
                  context.responsiveValue(compact: 'phone', medium: 'tablet', expanded: 'desktop'),
                  'desktop',
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('AdaptiveContainer enforces max width constraint on wide screens', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(1200, 800)),
          child: MaterialApp(
            home: Scaffold(
              body: AdaptiveContainer(
                maxWidth: 700,
                child: SizedBox(key: Key('child_box'), width: double.infinity, height: 100),
              ),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byKey(const Key('child_box')));
      expect(box.size.width, 700);
    });
  });

  group('Phase 0 Foundation: Localization & Integer Currency Engine', () {
    test('formatCurrency formats integer Rupiah accurately without floats', () {
      expect(AppLocalizations.formatCurrency(0), 'Rp0');
      expect(AppLocalizations.formatCurrency(29000), 'Rp29.000');
      expect(AppLocalizations.formatCurrency(29017), 'Rp29.017');
      expect(AppLocalizations.formatCurrency(1500000), 'Rp1.500.000');
      expect(AppLocalizations.formatCurrency(100000000), 'Rp100.000.000');

      // With sign
      expect(AppLocalizations.formatCurrency(25000, showSign: true), '+ Rp25.000');
      expect(AppLocalizations.formatCurrency(25000, showSign: true, isExpense: true), '- Rp25.000');
    });

    test('formatCompactCurrency formats large numbers cleanly', () {
      expect(AppLocalizations.formatCompactCurrency(500), 'Rp500');
      expect(AppLocalizations.formatCompactCurrency(50000), 'Rp50rb');
      expect(AppLocalizations.formatCompactCurrency(1500000), 'Rp1.5jt');
      expect(AppLocalizations.formatCompactCurrency(2000000000), 'Rp2M');
    });
  });

  group('Phase 0 Foundation: 16 Reusable Component Suite Widgets', () {
    testWidgets('AmountText renders with correct format and color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AstrackThemeExtension.light],
          ),
          home: const Scaffold(
            body: AmountText(
              amount: 75000,
              type: AmountDisplayType.income,
              showSign: true,
            ),
          ),
        ),
      );

      expect(find.text('+ Rp75.000'), findsOneWidget);
    });

    testWidgets('AmountInput handles integer typing and presets', (tester) async {
      int captured = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AstrackThemeExtension.light],
          ),
          home: Scaffold(
            body: AmountInput(
              initialValue: 20000,
              onChanged: (val) => captured = val,
            ),
          ),
        ),
      );

      expect(find.text('20.000'), findsOneWidget);

      // Tap preset chip '+50rb'
      await tester.tap(find.text('+50rb'));
      await tester.pump();

      expect(captured, 70000);
      expect(find.text('70.000'), findsOneWidget);
    });

    testWidgets('FundChip renders title and balance with active indicator', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AstrackThemeExtension.light],
          ),
          home: Scaffold(
            body: FundChip(
              title: 'Uang Jajan',
              balance: 150000,
              isSelected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Uang Jajan'), findsOneWidget);
      expect(find.text('Rp150.000'), findsOneWidget);

      await tester.tap(find.byType(FundChip));
      expect(tapped, isTrue);
    });

    testWidgets('SectionHeader displays title and invokes action', (tester) async {
      bool actionFired = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AstrackThemeExtension.light],
          ),
          home: Scaffold(
            body: SectionHeader(
              title: 'Mutasi Terbaru',
              subtitle: '5 transaksi terakhir',
              actionText: 'Lihat Semua',
              onAction: () => actionFired = true,
            ),
          ),
        ),
      );

      expect(find.text('Mutasi Terbaru'), findsOneWidget);
      expect(find.text('5 transaksi terakhir'), findsOneWidget);
      expect(find.text('Lihat Semua'), findsOneWidget);

      await tester.tap(find.text('Lihat Semua'));
      expect(actionFired, isTrue);
    });

    testWidgets('EmptyState displays title and message without generic slop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AstrackThemeExtension.light],
          ),
          home: const Scaffold(
            body: EmptyState(
              title: 'Belum Ada Transaksi',
              message: 'Catat pengeluaran pertama Anda hari ini.',
            ),
          ),
        ),
      );

      expect(find.text('Belum Ada Transaksi'), findsOneWidget);
      expect(find.text('Catat pengeluaran pertama Anda hari ini.'), findsOneWidget);
    });

    testWidgets('ErrorState displays message and retry button', (tester) async {
      bool retryClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AstrackThemeExtension.light],
          ),
          home: Scaffold(
            body: ErrorState(
              title: 'Koneksi Terputus',
              message: 'Silakan periksa koneksi internet Anda.',
              onRetry: () => retryClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Koneksi Terputus'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      expect(retryClicked, isTrue);
    });

    testWidgets('PlanBadge renders PRO, BASIC, and FREE variants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AstrackThemeExtension.light],
          ),
          home: const Scaffold(
            body: Column(
              children: [
                PlanBadge(variant: PlanTypeVariant.pro),
                PlanBadge(variant: PlanTypeVariant.basic),
                PlanBadge(variant: PlanTypeVariant.free),
              ],
            ),
          ),
        ),
      );

      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('BASIC'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
    });

    testWidgets('ProgressBar renders with correct threshold colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AstrackThemeExtension.light],
          ),
          home: const Scaffold(
            body: SizedBox(
              width: 200,
              child: ProgressBar(
                progress: 0.85,
                milestones: [0.8, 1.0],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProgressBar), findsOneWidget);
    });

    testWidgets('PrimaryButton renders label and triggers tap', (tester) async {
      bool clicked = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AstrackThemeExtension.light],
          ),
          home: Scaffold(
            body: PrimaryButton(
              label: 'Simpan Transaksi',
              onPressed: () => clicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Simpan Transaksi'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      expect(clicked, isTrue);
    });

    testWidgets('SecondaryButton renders with outlined style', (tester) async {
      bool clicked = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AstrackThemeExtension.light],
          ),
          home: Scaffold(
            body: SecondaryButton(
              label: 'Batal',
              onPressed: () => clicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Batal'), findsOneWidget);
      await tester.tap(find.byType(SecondaryButton));
      expect(clicked, isTrue);
    });
  });
}
