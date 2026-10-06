import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:astrack/main.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:astrack/providers/finance_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ASTRACK smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
          ChangeNotifierProvider(create: (_) => FinanceProvider(storage)),
        ],
        child: const AstrackApp(),
      ),
    );

    // Let the splash animation timer complete
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(AstrackApp), findsOneWidget);
  });
}
