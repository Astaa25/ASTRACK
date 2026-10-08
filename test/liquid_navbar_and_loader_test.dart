import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/widgets/modern_bottom_nav.dart';
import 'package:astrack/widgets/liquid_loader.dart';

void main() {
  group('ModernBottomNav Liquid Glass Tests', () {
    testWidgets('renders all 4 tabs and center action FAB', (tester) async {
      int selectedTab = 0;
      bool fabPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ModernBottomNav(
              currentIndex: selectedTab,
              isDark: true,
              onTabSelected: (idx) => selectedTab = idx,
              onCenterFabPressed: () => fabPressed = true,
            ),
          ),
        ),
      );

      // Verify labels are displayed
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Keuangan'), findsOneWidget);
      expect(find.text('Statistik'), findsOneWidget);
      expect(find.text('Lainnya'), findsOneWidget);

      // Verify Center FAB '+' icon
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Tap on Keuangan tab
      await tester.tap(find.text('Keuangan'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals(1));

      // Tap on Statistik tab
      await tester.tap(find.text('Statistik'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals(2));

      // Tap on Lainnya tab
      await tester.tap(find.text('Lainnya'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals(3));

      // Tap on Center FAB
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(fabPressed, isTrue);
    });

    testWidgets('renders properly in light mode without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            bottomNavigationBar: ModernBottomNav(
              currentIndex: 2,
              isDark: false,
              onTabSelected: (_) {},
              onCenterFabPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ModernBottomNav), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });

  group('AstrackLiquidLoader Tests', () {
    testWidgets('renders compact liquid loader correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AstrackLiquidLoader.compact(size: 24),
            ),
          ),
        ),
      );

      expect(find.byType(AstrackLiquidLoader), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('renders full liquid loader with rotating messages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AstrackLiquidLoader.full(
                initialMessage: 'Menyelaraskan buku kas...',
                size: 80,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Menyelaraskan buku kas...'), findsOneWidget);
      expect(find.byType(AstrackLiquidLoader), findsOneWidget);

      // Let animation tick
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AstrackLiquidLoader), findsOneWidget);
    });
  });
}
