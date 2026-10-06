import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/models/savings_goal.dart';

void main() {
  group('ASTRACK Phase 5 — Savings Goal Metric & Status Tests', () {
    test('Calculates remaining amount and recommended daily/monthly savings correctly', () {
      final deadline = DateTime.now().add(const Duration(days: 30));
      final goal = SavingsGoal(
        id: 'g1',
        name: 'Liburan Akhir Tahun',
        targetAmount: 3000000,
        currentAmount: 1500000,
        sourceId: 's1',
        sourceName: 'Dompet',
        deadline: deadline,
      );

      expect(goal.remainingAmount, equals(1500000.0));
      expect(goal.daysRemaining, greaterThanOrEqualTo(29));
      expect(goal.recommendedDailySaving, closeTo(50000.0, 2000.0));
      expect(goal.isCompleted, isFalse);
      expect(goal.status, equals(SavingsGoalStatus.onTrack));
    });

    test('Marks completed goal as completed and stops recommendations', () {
      final goal = SavingsGoal(
        id: 'g2',
        name: 'Beli Gadget',
        targetAmount: 2000000,
        currentAmount: 2000000,
        sourceId: 's1',
        sourceName: 'Dompet',
        deadline: DateTime.now().add(const Duration(days: 10)),
      );

      expect(goal.isCompleted, isTrue);
      expect(goal.remainingAmount, equals(0.0));
      expect(goal.recommendedDailySaving, equals(0.0));
      expect(goal.status, equals(SavingsGoalStatus.completed));
    });

    test('Marks goal as behind when deadline is approaching but savings are lagging', () {
      final urgentDeadline = DateTime.now().add(const Duration(days: 15));
      final goal = SavingsGoal(
        id: 'g3',
        name: 'Darurat Medis',
        targetAmount: 10000000,
        currentAmount: 1000000, // Only 10%
        sourceId: 's1',
        sourceName: 'Dompet',
        deadline: urgentDeadline,
      );

      expect(goal.status, equals(SavingsGoalStatus.behind));
      expect(goal.status.label, contains('Perlu Dikejar'));
    });
  });
}
