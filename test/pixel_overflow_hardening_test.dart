import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:astrack/providers/finance_provider.dart';
import 'package:astrack/features/admin/admin_statistics_screen.dart';
import 'package:astrack/features/statistics/statistics_screen.dart';
import 'package:astrack/features/dashboard/dashboard_screen.dart';

Widget createTestWidget({
  required Widget child,
  required ThemeProvider themeProvider,
  required FinanceProvider financeProvider,
  Size size = const Size(360, 700),
  double textScale = 1.0,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ChangeNotifierProvider<FinanceProvider>.value(value: financeProvider),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late ThemeProvider themeProvider;
  late FinanceProvider financeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    themeProvider = ThemeProvider(storage);
    financeProvider = FinanceProvider(storage);
  });

  group('Pixel Overflow Regression Tests (Compact 360dp Screen)', () {
    testWidgets('AdminStatisticsScreen renders MRR & KPI cards without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 700));

      await tester.pumpWidget(createTestWidget(
        child: const AdminStatisticsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(360, 700),
      ));
      await tester.pumpAndSettle();

      expect(find.text('MRR (Omset/Bln)'), findsOneWidget);
      expect(find.text('Conversion Rate'), findsOneWidget);
      expect(find.text('Pengguna Aktif'), findsOneWidget);
      expect(find.text('Pengguna PRO'), findsOneWidget);
      expect(tester.takeException(), isNull); // ZERO OVERFLOW
    });

    testWidgets('StatisticsScreen Tab 1 mini health banner renders without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 700));

      await tester.pumpWidget(createTestWidget(
        child: const StatisticsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(360, 700),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Skor Finansial:'), findsOneWidget);
      expect(find.textContaining('Lihat analisis 4 pilar'), findsOneWidget);
      expect(tester.takeException(), isNull); // ZERO OVERFLOW
    });

    testWidgets('StatisticsScreen Tab 3 (Skor Kesehatan) renders circular score card without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 700));

      await tester.pumpWidget(createTestWidget(
        child: const StatisticsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(360, 700),
      ));
      await tester.pumpAndSettle();

      // Tap on Tab 3 (Skor Kesehatan)
      await tester.tap(find.text('Skor Kesehatan'));
      await tester.pumpAndSettle();

      expect(find.text('4 Pilar Penilaian Finansial'), findsOneWidget);
      expect(tester.takeException(), isNull); // ZERO OVERFLOW
    });

    testWidgets('DashboardScreen financial health quick card renders without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 700));

      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
        debugPrint('CAUGHT OVERFLOW: ${details.summary}');
        for (final info in details.informationCollector?.call() ?? <DiagnosticsNode>[]) {
          debugPrint('INFO: ${info.name} => ${info.toDescription()}');
        }
      };

      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(360, 700),
      ));
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;
      expect(caughtDetails, isNull);
      final exc = tester.takeException();
      expect(exc, isNull); // ZERO OVERFLOW
    });
  });
}
