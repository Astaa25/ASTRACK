import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_item.dart';
import '../models/fund_source.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/recurring_transaction.dart';

enum SyncEngineStatus {
  synced,
  pending,
  syncing,
  failed,
  offline,
}

class SyncResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final int downloadedCount;
  final DateTime syncTime;

  SyncResult({
    required this.success,
    required this.message,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    required this.syncTime,
  });
}

class FinancialSyncService {
  static final FinancialSyncService _instance = FinancialSyncService._internal();
  factory FinancialSyncService() => _instance;
  FinancialSyncService._internal();

  final ValueNotifier<SyncEngineStatus> statusNotifier = ValueNotifier<SyncEngineStatus>(SyncEngineStatus.synced);
  DateTime? lastSyncTime;
  int pendingCount = 0;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isCloudAvailable {
    final client = _supabase;
    return client != null && client.auth.currentUser != null;
  }

  String? get currentUserId => _supabase?.auth.currentUser?.id;

  /// Sync all financial collections with Supabase PostgreSQL
  Future<SyncResult> syncAll({
    required List<FundSource> sources,
    required List<FinancialCategory> categories,
    required List<TransactionItem> transactions,
    required List<Budget> budgets,
    required List<SavingsGoal> savings,
    required List<RecurringTransaction> recurring,
    required Function(List<FundSource> s, List<FinancialCategory> c, List<TransactionItem> t, List<Budget> b, List<SavingsGoal> g, List<RecurringTransaction> r) onRemoteMerged,
  }) async {
    final client = _supabase;
    final userId = currentUserId;

    if (client == null || userId == null) {
      statusNotifier.value = SyncEngineStatus.offline;
      return SyncResult(
        success: false,
        message: 'Mode offline atau pengguna belum login cloud.',
        syncTime: DateTime.now(),
      );
    }

    statusNotifier.value = SyncEngineStatus.syncing;
    int uploaded = 0;
    int downloaded = 0;

    try {
      // 1. SYNC FUND SOURCES (Push local to cloud)
      for (final src in sources) {
        await client.from('fund_sources').upsert({
          'id': src.id,
          'user_id': userId,
          'name': src.name,
          'balance': src.balance,
          'icon_name': src.iconName,
          'color_hex': src.colorHex,
          'is_active': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        uploaded++;
      }

      // 2. SYNC TRANSACTIONS (Push local to cloud)
      for (final tx in transactions) {
        await client.from('transactions').upsert({
          'id': tx.id,
          'user_id': userId,
          'type': tx.type.name,
          'amount': tx.amount,
          'description': tx.description,
          'category_id': tx.categoryId,
          'category_name': tx.categoryName,
          'source_id': tx.sourceId,
          'source_name': tx.sourceName,
          'target_source_id': tx.targetSourceId,
          'target_source_name': tx.targetSourceName,
          'savings_goal_id': tx.savingsGoalId,
          'recurring_id': tx.recurringId,
          'date_time': tx.dateTime.toUtc().toIso8601String(),
          'notes': tx.notes,
          'sync_status': 'synced',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        uploaded++;
      }

      // 3. SYNC BUDGETS
      for (final bg in budgets) {
        await client.from('budgets').upsert({
          'id': bg.id,
          'user_id': userId,
          'category_id': bg.categoryId,
          'category_name': bg.categoryName,
          'limit_amount': bg.limitAmount,
          'spent_amount': bg.spentAmount,
          'month': bg.month,
          'year': bg.year,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        uploaded++;
      }

      // 4. SYNC SAVINGS GOALS
      for (final sg in savings) {
        await client.from('savings_goals').upsert({
          'id': sg.id,
          'user_id': userId,
          'name': sg.name,
          'target_amount': sg.targetAmount,
          'current_amount': sg.currentAmount,
          'target_date': sg.deadline?.toUtc().toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
          'color_hex': sg.colorHex,
          'icon_name': sg.iconName,
          'source_id': sg.sourceId,
          'source_name': sg.sourceName,
          'is_completed': sg.isCompleted,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        uploaded++;
      }

      // 5. SYNC RECURRING TRANSACTIONS
      for (final rc in recurring) {
        await client.from('recurring_transactions').upsert({
          'id': rc.id,
          'user_id': userId,
          'name': rc.name,
          'amount': rc.amount,
          'type': rc.type.name,
          'category_id': rc.categoryId,
          'category_name': rc.categoryName,
          'source_id': rc.sourceId,
          'source_name': rc.sourceName,
          'frequency': rc.frequency.name,
          'start_date': rc.startDate.toUtc().toIso8601String(),
          'next_occurrence': rc.nextOccurrence.toUtc().toIso8601String(),
          'end_date': rc.endDate?.toUtc().toIso8601String(),
          'is_active': rc.isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        uploaded++;
      }

      // --- PULL REMOTE DATA (Cloud -> Local) ---
      final remoteSourcesRes = await client.from('fund_sources').select().eq('user_id', userId);
      final remoteTxRes = await client.from('transactions').select().eq('user_id', userId).order('date_time', ascending: false);
      final remoteBudgetsRes = await client.from('budgets').select().eq('user_id', userId);
      final remoteSavingsRes = await client.from('savings_goals').select().eq('user_id', userId);
      final remoteRecurringRes = await client.from('recurring_transactions').select().eq('user_id', userId);

      final mergedSources = <FundSource>[...sources];
      for (final row in remoteSourcesRes) {
        final id = row['id'] as String;
        final idx = mergedSources.indexWhere((s) => s.id == id);
        final item = FundSource(
          id: id,
          name: row['name'] as String,
          balance: double.tryParse(row['balance'].toString()) ?? 0.0,
          iconName: row['icon_name'] as String? ?? 'wallet',
          colorHex: row['color_hex'] as String? ?? '087F5B',
        );
        if (idx != -1) {
          mergedSources[idx] = item;
        } else {
          mergedSources.add(item);
          downloaded++;
        }
      }

      final mergedTransactions = <TransactionItem>[...transactions];
      for (final row in remoteTxRes) {
        final id = row['id'] as String;
        final idx = mergedTransactions.indexWhere((t) => t.id == id);
        final item = TransactionItem(
          id: id,
          type: TransactionType.values.firstWhere((e) => e.name == row['type'], orElse: () => TransactionType.expense),
          amount: double.tryParse(row['amount'].toString()) ?? 0.0,
          description: row['description'] as String? ?? '',
          categoryId: row['category_id'] as String? ?? '',
          categoryName: row['category_name'] as String? ?? '',
          sourceId: row['source_id'] as String? ?? '',
          sourceName: row['source_name'] as String? ?? '',
          targetSourceId: row['target_source_id'] as String?,
          targetSourceName: row['target_source_name'] as String?,
          savingsGoalId: row['savings_goal_id'] as String?,
          recurringId: row['recurring_id'] as String?,
          dateTime: DateTime.parse(row['date_time']).toLocal(),
          notes: (row['notes'] as String?) ?? '',
        );
        if (idx != -1) {
          mergedTransactions[idx] = item;
        } else {
          mergedTransactions.add(item);
          downloaded++;
        }
      }

      final mergedBudgets = <Budget>[...budgets];
      for (final row in remoteBudgetsRes) {
        final id = row['id'] as String;
        final idx = mergedBudgets.indexWhere((b) => b.id == id);
        final item = Budget(
          id: id,
          categoryId: row['category_id'] as String,
          categoryName: row['category_name'] as String,
          limitAmount: double.tryParse(row['limit_amount'].toString()) ?? 0.0,
          spentAmount: double.tryParse(row['spent_amount'].toString()) ?? 0.0,
          month: row['month'] as int,
          year: row['year'] as int,
        );
        if (idx != -1) {
          mergedBudgets[idx] = item;
        } else {
          mergedBudgets.add(item);
          downloaded++;
        }
      }

      final mergedSavings = <SavingsGoal>[...savings];
      for (final row in remoteSavingsRes) {
        final id = row['id'] as String;
        final idx = mergedSavings.indexWhere((g) => g.id == id);
        final item = SavingsGoal(
          id: id,
          name: row['name'] as String,
          targetAmount: double.tryParse(row['target_amount'].toString()) ?? 0.0,
          currentAmount: double.tryParse(row['current_amount'].toString()) ?? 0.0,
          deadline: row['target_date'] != null ? DateTime.parse(row['target_date']).toLocal() : null,
          colorHex: row['color_hex'] as String? ?? '10B981',
          iconName: row['icon_name'] as String? ?? 'savings',
          sourceId: row['source_id'] as String? ?? 'src_default',
          sourceName: row['source_name'] as String? ?? 'Dompet',
        );
        if (idx != -1) {
          mergedSavings[idx] = item;
        } else {
          mergedSavings.add(item);
          downloaded++;
        }
      }

      final mergedRecurring = <RecurringTransaction>[...recurring];
      for (final row in remoteRecurringRes) {
        final id = row['id'] as String;
        final idx = mergedRecurring.indexWhere((r) => r.id == id);
        final item = RecurringTransaction(
          id: id,
          description: row['name'] as String,
          amount: double.tryParse(row['amount'].toString()) ?? 0.0,
          type: TransactionType.values.firstWhere((e) => e.name == row['type'], orElse: () => TransactionType.expense),
          categoryId: row['category_id'] as String,
          categoryName: row['category_name'] as String,
          sourceId: row['source_id'] as String,
          sourceName: row['source_name'] as String,
          frequency: RecurringFrequency.values.firstWhere((e) => e.name == row['frequency'], orElse: () => RecurringFrequency.monthly),
          startDate: DateTime.parse(row['start_date']).toLocal(),
          nextOccurrence: DateTime.parse(row['next_occurrence']).toLocal(),
          endDate: row['end_date'] != null ? DateTime.parse(row['end_date']).toLocal() : null,
          isActive: row['is_active'] as bool? ?? true,
        );
        if (idx != -1) {
          mergedRecurring[idx] = item;
        } else {
          mergedRecurring.add(item);
          downloaded++;
        }
      }

      onRemoteMerged(mergedSources, categories, mergedTransactions, mergedBudgets, mergedSavings, mergedRecurring);

      lastSyncTime = DateTime.now();
      pendingCount = 0;
      statusNotifier.value = SyncEngineStatus.synced;

      return SyncResult(
        success: true,
        message: 'Sinkronisasi cloud berhasil.',
        uploadedCount: uploaded,
        downloadedCount: downloaded,
        syncTime: lastSyncTime!,
      );
    } catch (e) {
      statusNotifier.value = SyncEngineStatus.failed;
      return SyncResult(
        success: false,
        message: 'Sinkronisasi gagal: $e',
        syncTime: DateTime.now(),
      );
    }
  }

  /// Delete a remote transaction when deleted locally
  Future<void> deleteRemoteTransaction(String transactionId) async {
    final client = _supabase;
    final userId = currentUserId;
    if (client == null || userId == null) return;
    try {
      await client.from('transactions').delete().match({'id': transactionId, 'user_id': userId});
    } catch (_) {}
  }
}
