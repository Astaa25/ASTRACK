import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_message.dart';
import '../models/transaction_item.dart';
import '../models/fund_source.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import 'saas_backend_service.dart';
import 'ai/ai_models.dart';
import 'ai/ai_provider.dart';

export 'ai/ai_models.dart';
export 'ai/ai_provider.dart';

class AIService {
  static const _uuid = Uuid();
  static AIProvider _activeProvider = LocalRuleAIProvider();

  // Active draft for context continuation
  static TransactionItem? _pendingDraft;

  static void setProvider(AIProvider provider) {
    _activeProvider = provider;
  }

  static AIProvider get currentProvider => _activeProvider;

  /// Clear any pending draft
  static void clearPendingDraft() {
    _pendingDraft = null;
  }

  /// Process natural language input from the user
  static Future<AIMessage> processInput({
    required String rawInput,
    required List<FundSource> availableSources,
    required List<FinancialCategory> availableCategories,
    required List<TransactionItem> existingTransactions,
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
    String? userId,
  }) async {
    // Artificial subtle processing pause (150-250ms) for natural conversational feel
    await Future.delayed(const Duration(milliseconds: 180));

    // Dynamic User Identification
    String uid = userId ?? 'guest_user';
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser != null) {
        uid = authUser.id;
      }
    } catch (_) {}

    // FEATURE GUARD: Check AI Quota
    final hasQuota = await SaaSBackendService().checkAndConsumeAiQuota(uid);
    if (!hasQuota) {
      return AIMessage(
        id: _uuid.v4(),
        text: '❌ **Kuota AI Bulanan Habis!**\nBatas penggunaan AI untuk paket langganan Anda bulan ini telah tercapai. Harap *Upgrade ke Paket Pro* untuk terus menikmati Asisten AI tanpa batas.',
        isUser: false,
        confidenceLevel: 'high',
      );
    }

    final context = AIContext(
      availableSources: availableSources,
      availableCategories: availableCategories,
      existingTransactions: existingTransactions,
      budgets: budgets,
      savingsGoals: savingsGoals,
      userId: uid,
    );

    final response = await _activeProvider.processInput(
      rawInput: rawInput,
      context: context,
      pendingDraft: _pendingDraft,
    );

    // Update pending draft context
    if (response.clarificationOptions != null && response.draftTransaction != null) {
      _pendingDraft = response.draftTransaction;
    } else {
      _pendingDraft = null;
    }

    return response;
  }
}
