import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../models/ai_message.dart';
import '../../models/transaction_item.dart';
import '../../models/fund_source.dart';
import '../../models/category.dart';
import '../../core/utils/currency_formatter.dart';
import '../ai_category_classifier.dart';
import '../../models/budget.dart';
import '../../models/savings_goal.dart';
import '../financial_health_service.dart';
import 'ai_models.dart';

class PromptInjectionDetector {
  static final List<RegExp> _injectionPatterns = [
    RegExp(r'(ignore|abaikan|lupakan)\s+(all|previous|semua|instruksi|aturan)', caseSensitive: false),
    RegExp(r'(system\s*prompt|developer\s*instructions?|instruksi\s*sistem|prompt\s*awal)', caseSensitive: false),
    RegExp(r'(reveal|tampilkan|bocorkan|show)\s+(prompt|api\s*key|secret|kunci|token)', caseSensitive: false),
    RegExp(r'(jailbreak|dan\s+mode|developer\s*mode|mode\s*pengembang)', caseSensitive: false),
    RegExp(r'(drop\s+table|delete\s+from|truncate\s+table|drop\s+database|rm\s+-rf)', caseSensitive: false),
    RegExp(r'(ubah\s+saldo\s+menjadi|set\s+saldo\s+jadi|update\s+balance\s+directly)', caseSensitive: false),
    RegExp(r'(service_role|supabase_key|admin_key)', caseSensitive: false),
    RegExp(r'(jadikan\s+saya\s+admin|make\s+me\s+admin|bypass\s+(paywall|subscription|auth))', caseSensitive: false),
  ];

  static bool isInjectionAttempt(String text) {
    for (final pattern in _injectionPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }
}

abstract class AIProvider {
  String get name;
  Future<AIMessage> processInput({
    required String rawInput,
    required AIContext context,
    TransactionItem? pendingDraft,
  });
}

class LocalRuleAIProvider implements AIProvider {
  static const _uuid = Uuid();

  @override
  String get name => 'Local Natural Language Engine';

  @override
  Future<AIMessage> processInput({
    required String rawInput,
    required AIContext context,
    TransactionItem? pendingDraft,
  }) async {
    final input = rawInput.trim();
    final lower = input.toLowerCase();

    // 0. Security Guardrail: Prompt Injection Detection
    if (PromptInjectionDetector.isInjectionAttempt(input)) {
      return AIMessage(
        id: _uuid.v4(),
        text: '⚠️ **Instruksi Tidak Sah Terdeteksi**\n'
            'Asisten AI ASTRACK beroperasi dengan guardrail keamanan keuangan zero-trust. '
            'Saya tidak dapat menjalankan manipulasi instruksi internal, bypass sistem, pembaruan saldo langsung tanpa ledger, atau pembocoran konfigurasi rahasia. '
            'Bagaimana saya dapat membantu pencatatan atau analisis keuangan Anda?',
        isUser: false,
        confidenceLevel: 'high',
      );
    }

    // 1. Context Continuation check: If there is a pending draft awaiting source or clarification
    if (pendingDraft != null) {
      final matchingSource = _findMatchingSource(input, context.availableSources);
      if (matchingSource != null) {
        final completedDraft = pendingDraft.copyWith(
          sourceId: matchingSource.id,
          sourceName: matchingSource.name,
        );

        return AIMessage(
          id: _uuid.v4(),
          text: 'Baik, sumber dana menggunakan **${matchingSource.name}**. Silakan tinjau dan konfirmasi transaksi Anda:',
          isUser: false,
          draftTransaction: completedDraft,
          confidenceLevel: 'high',
        );
      }
    }

    // 2. What-If Simulation check
    if (lower.contains('kalau') || lower.contains('simulasi') || (lower.contains('saldo') && lower.contains('jadi berapa'))) {
      return _handleWhatIfSimulation(input, context.availableSources);
    }

    // 3. Financial Health & Advice Queries
    if (lower.contains('kesehatan finansial') ||
        lower.contains('skor finansial') ||
        lower.contains('skor kesehatan') ||
        lower.contains('tips hemat') ||
        lower.contains('rekomendasi hemat') ||
        lower.contains('saran keuangan')) {
      return _answerFinancialHealth(context);
    }

    // 4. Budget Intent (Drafting or Status Query)
    final budgetResponse = _handleBudgetIntent(input, context);
    if (budgetResponse != null) {
      return budgetResponse;
    }

    // 5. Savings Goal Intent (Drafting)
    final savingsResponse = _handleSavingsGoalIntent(input, context);
    if (savingsResponse != null) {
      return savingsResponse;
    }

    // 6. Financial Q&A Queries
    if (lower.contains('habis berapa') ||
        (lower.contains('pengeluaran') && (lower.contains('bulan') || lower.contains('total'))) ||
        lower.contains('total pengeluaran')) {
      return _answerTotalExpenseQuestion(context.existingTransactions);
    }

    if (lower.contains('paling banyak habis') ||
        lower.contains('kategori apa yang paling banyak') ||
        lower.contains('terbesar') ||
        lower.contains('paling boros')) {
      return _answerTopExpenseCategory(context.existingTransactions);
    }

    if (lower.contains('uang saya sekarang') ||
        lower.contains('saldo saya') ||
        lower.contains('total saldo')) {
      final totalBal = context.availableSources.fold(0.0, (sum, s) => sum + s.balance);
      return AIMessage(
        id: _uuid.v4(),
        text: 'Total saldo Anda di seluruh sumber dana saat ini adalah **${CurrencyFormatter.format(totalBal)}**.',
        isUser: false,
      );
    }

    if (lower.contains('berapa kali') || lower.contains('sering')) {
      return _answerItemFrequency(input, context.existingTransactions);
    }

    if (lower.contains('transaksi di atas') || lower.contains('pengeluaran besar') || lower.contains('nominal besar')) {
      return _answerFilteredTransactions(input, context.existingTransactions);
    }

    // 7. Parse Transaction Draft
    return _parseTransactionIntent(input, context);
  }

  AIMessage _parseTransactionIntent(String input, AIContext context) {
    final lower = input.toLowerCase();
    final amount = _extractAmount(input);

    if (amount == null || amount <= 0) {
      return AIMessage(
        id: _uuid.v4(),
        text: 'Halo! Saya asisten finansial ASTRACK. Anda dapat mencatat transaksi seperti:\n'
            '• *"Beli kopi susu 25 ribu dari Uang Jajan"*\n'
            '• *"Dapat gaji 5 juta ke Tabungan"*\n'
            '• *"Pindah 100 ribu dari Mandiri ke GoPay"*\n'
            'Atau tanyakan: *"Berapa pengeluaran saya bulan ini?"*',
        isUser: false,
      );
    }

    // Determine Transaction Type
    TransactionType type = TransactionType.expense;
    if (lower.contains('gaji') ||
        lower.contains('dapat') ||
        lower.contains('bonus') ||
        lower.contains('terima') ||
        lower.contains('masuk') ||
        lower.contains('pendapatan') ||
        lower.contains('penghasilan') ||
        lower.contains('untung')) {
      type = TransactionType.income;
    } else if (lower.contains('pindah') || lower.contains('transfer') || lower.contains('kirim')) {
      type = TransactionType.transfer;
    } else if (lower.contains('tabung') || lower.contains('simpan ke tabungan')) {
      type = TransactionType.saving;
    }

    // Extract Source of Funds
    FundSource? source = _findMatchingSource(input, context.availableSources);
    FundSource? targetSource;

    if (type == TransactionType.transfer || type == TransactionType.saving) {
      targetSource = _findMatchingTargetSource(input, context.availableSources, source);
    }

    // If source is not mentioned, ask for clarification
    if (source == null) {
      final defaultCategory = _classifyCategory(input, type, context.availableCategories);
      final draftWithoutSource = TransactionItem(
        id: 'tx_ai_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        amount: amount,
        description: _extractDescription(input),
        categoryId: defaultCategory.id,
        categoryName: defaultCategory.name,
        sourceId: '',
        sourceName: '',
        targetSourceId: targetSource?.id,
        targetSourceName: targetSource?.name,
        dateTime: DateTime.now(),
        notes: 'Catatan via Asisten AI',
      );

      final sourceOptions = context.availableSources.map((s) => s.name).toList();
      return AIMessage(
        id: _uuid.v4(),
        text: 'Transaksi **${CurrencyFormatter.format(amount)}** untuk **${draftWithoutSource.description}** siap dicatat. Mau dibayar/dicatat dari sumber dana mana?',
        isUser: false,
        clarificationOptions: sourceOptions,
        draftTransaction: draftWithoutSource,
        confidenceLevel: 'medium',
      );
    }

    final category = _classifyCategory(input, type, context.availableCategories);
    final description = _extractDescription(input);

    final draft = TransactionItem(
      id: 'tx_ai_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      amount: amount,
      description: description,
      categoryId: category.id,
      categoryName: category.name,
      sourceId: source.id,
      sourceName: source.name,
      targetSourceId: targetSource?.id,
      targetSourceName: targetSource?.name,
      dateTime: DateTime.now(),
      notes: 'Catatan otomatis Asisten AI ASTRACK',
    );

    final isAmbiguousAmount = lower.contains('sekitar') ||
        lower.contains('kira-kira') ||
        lower.contains('kurang lebih') ||
        lower.contains('mungkin');

    return AIMessage(
      id: _uuid.v4(),
      text: isAmbiguousAmount
          ? 'Jumlah nominal diperkirakan sekitar **${CurrencyFormatter.format(amount)}**. Mohon periksa kembali rincian draf berikut sebelum konfirmasi:'
          : 'Berikut draf transaksi Anda. Silakan periksa dan konfirmasi:',
      isUser: false,
      draftTransaction: draft,
      confidenceLevel: isAmbiguousAmount ? 'medium' : 'high',
    );
  }

  AIMessage _handleWhatIfSimulation(String input, List<FundSource> sources) {
    final amount = _extractAmount(input) ?? 0.0;
    final source = _findMatchingSource(input, sources) ?? (sources.isNotEmpty ? sources.first : null);

    if (source == null) {
      return AIMessage(
        id: _uuid.v4(),
        text: 'Tidak ada sumber dana yang tersedia untuk simulasi.',
        isUser: false,
        isSimulation: true,
      );
    }

    final newBalance = source.balance - amount;
    return AIMessage(
      id: _uuid.v4(),
      text: '📊 **Simulasi Pengeluaran:**\nJika Anda menambah pengeluaran sebesar **${CurrencyFormatter.format(amount)}**, saldo **${source.name}** Anda yang sekarang **${CurrencyFormatter.format(source.balance)}** akan menjadi **${CurrencyFormatter.format(newBalance)}**.',
      isUser: false,
      isSimulation: true,
    );
  }

  AIMessage _answerTotalExpenseQuestion(List<TransactionItem> transactions) {
    final now = DateTime.now();
    final thisMonthExpenses = transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.dateTime.month == now.month &&
        t.dateTime.year == now.year);

    final total = thisMonthExpenses.fold(0.0, (sum, t) => sum + t.amount);
    final count = thisMonthExpenses.length;

    return AIMessage(
      id: _uuid.v4(),
      text: 'Bulan ini Anda telah mencatat **$count pengeluaran** dengan total **${CurrencyFormatter.format(total)}**.',
      isUser: false,
    );
  }

  AIMessage _answerTopExpenseCategory(List<TransactionItem> transactions) {
    final now = DateTime.now();
    final categoryTotals = <String, double>{};

    for (final t in transactions) {
      if (t.type == TransactionType.expense && t.dateTime.month == now.month && t.dateTime.year == now.year) {
        categoryTotals[t.categoryName] = (categoryTotals[t.categoryName] ?? 0.0) + t.amount;
      }
    }

    if (categoryTotals.isEmpty) {
      return AIMessage(
        id: _uuid.v4(),
        text: 'Belum ada data pengeluaran yang tercatat untuk bulan ini.',
        isUser: false,
      );
    }

    var topCategory = categoryTotals.keys.first;
    var maxVal = categoryTotals[topCategory]!;
    categoryTotals.forEach((cat, val) {
      if (val > maxVal) {
        maxVal = val;
        topCategory = cat;
      }
    });

    return AIMessage(
      id: _uuid.v4(),
      text: 'Pengeluaran terbesar Anda bulan ini ada di kategori **$topCategory** dengan total **${CurrencyFormatter.format(maxVal)}**.',
      isUser: false,
    );
  }

  AIMessage _answerItemFrequency(String input, List<TransactionItem> transactions) {
    final lower = input.toLowerCase();
    String query = 'kopi';
    if (lower.contains('bensin')) query = 'bensin';
    if (lower.contains('makan')) query = 'makan';

    final matched = transactions.where((t) =>
        t.description.toLowerCase().contains(query) ||
        t.categoryName.toLowerCase().contains(query)).toList();

    final total = matched.fold(0.0, (sum, t) => sum + t.amount);

    return AIMessage(
      id: _uuid.v4(),
      text: 'Pengeluaran untuk **$query** muncul sebanyak **${matched.length} kali** dengan total **${CurrencyFormatter.format(total)}**.',
      isUser: false,
    );
  }

  AIMessage _answerFilteredTransactions(String input, List<TransactionItem> transactions) {
    final amount = _extractAmount(input) ?? 100000;
    final matched = transactions.where((t) => t.amount >= amount).toList();

    if (matched.isEmpty) {
      return AIMessage(
        id: _uuid.v4(),
        text: 'Tidak ada transaksi dengan nominal di atas ${CurrencyFormatter.format(amount)}.',
        isUser: false,
      );
    }

    final buffer = StringBuffer('Berikut transaksi di atas **${CurrencyFormatter.format(amount)}**:\n\n');
    for (final t in matched.take(5)) {
      buffer.writeln('• **${t.description}**: ${CurrencyFormatter.format(t.amount)} (${t.sourceName})');
    }
    return AIMessage(
      id: _uuid.v4(),
      text: buffer.toString(),
      isUser: false,
    );
  }

  FundSource? _findMatchingSource(String text, List<FundSource> sources) {
    final lower = text.toLowerCase();
    for (final src in sources) {
      if (lower.contains(src.name.toLowerCase())) {
        return src;
      }
    }
    return null;
  }

  FundSource? _findMatchingTargetSource(String text, List<FundSource> sources, FundSource? primarySource) {
    final lower = text.toLowerCase();
    for (final src in sources) {
      if (primarySource != null && src.id == primarySource.id) continue;
      if (lower.contains(src.name.toLowerCase())) {
        return src;
      }
    }
    return null;
  }

  double? _extractAmount(String text) {
    final lower = text.toLowerCase();
    final parts = lower.split(RegExp(r'\b(ralat|salah|bukan)\b'));

    for (var part in parts.reversed) {
      final jutaMatch = RegExp(r'(\d+([\.,]\d+)?)\s*(juta|jt)').firstMatch(part);
      if (jutaMatch != null) {
        return (double.tryParse(jutaMatch.group(1)!.replaceAll(',', '.')) ?? 1.0) * 1000000.0;
      }

      final ribuMatch = RegExp(r'(\d+([\.,]\d+)?)\s*(ribu|rb|k\b)').firstMatch(part);
      if (ribuMatch != null) {
        return (double.tryParse(ribuMatch.group(1)!.replaceAll(',', '.')) ?? 1.0) * 1000.0;
      }

      final rpMatch = RegExp(r'(?:rp\.?\s*)([\d\.,]+)').firstMatch(part);
      if (rpMatch != null) {
        final cleaned = rpMatch.group(1)!.replaceAll('.', '').replaceAll(',', '');
        final val = double.tryParse(cleaned);
        if (val != null && val > 0) return val;
      }

      final numMatch = RegExp(r'\b(\d{4,9})\b').firstMatch(part);
      if (numMatch != null) {
        return double.tryParse(numMatch.group(1)!);
      }
    }
    return null;
  }

  String _extractDescription(String text) {
    var cleaned = text.replaceAll(RegExp(r'(\d+([\.,]\d+)?)\s*(juta|jt|ribu|rb|k\b)', caseSensitive: false), '')
        .replaceAll(RegExp(r'rp\.?\s*[\d\.,]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(beli|bayar|tadi|dapat|terima|pindah|transfer|ke|dari|untuk|uang)\b', caseSensitive: false), '')
        .trim();
    if (cleaned.isEmpty) return 'Transaksi';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  FinancialCategory _classifyCategory(String text, TransactionType type, List<FinancialCategory> available) {
    final lower = text.toLowerCase();
    // Prioritize direct match against available user categories
    for (final cat in available) {
      final catLower = cat.name.toLowerCase();
      if (lower.contains(catLower) || (catLower == 'coffee' && lower.contains('kopi')) || (catLower.contains('kopi') && lower.contains('coffee'))) {
        return cat;
      }
    }

    final cls = AICategoryClassifier.classify(text, type == TransactionType.expense);
    final catName = cls.name;
    final existing = available.where((c) => c.name.toLowerCase() == catName.toLowerCase());
    if (existing.isNotEmpty) {
      return existing.first;
    }
    if (available.isNotEmpty) {
      return available.first;
    }
    return FinancialCategory(
      id: 'cat_${catName.toLowerCase().replaceAll(' ', '_')}',
      name: catName,
      iconName: cls.icon,
      colorHex: cls.color,
      type: type == TransactionType.income ? CategoryType.income : CategoryType.expense,
    );
  }

  AIMessage? _handleBudgetIntent(String input, AIContext context) {
    final lower = input.toLowerCase();
    final isCreation = lower.contains('buat budget') ||
        lower.contains('set budget') ||
        lower.contains('pasang budget') ||
        lower.contains('atur budget') ||
        lower.contains('tambah budget') ||
        lower.contains('anggaran baru');

    if (!isCreation) {
      if (lower.contains('sisa budget') ||
          lower.contains('status budget') ||
          lower.contains('cek budget') ||
          lower.contains('overbudget')) {
        return _answerBudgetStatus(context);
      }
      return null;
    }

    final amount = _extractAmount(input);
    if (amount == null || amount <= 0) {
      return AIMessage(
        id: _uuid.v4(),
        text: 'Berapa batas anggaran yang ingin Anda tentukan? Contoh: *"Set budget makanan 1.5 juta"* atau *"Buat budget total 5 juta"*.',
        isUser: false,
      );
    }

    final isOverall = lower.contains('total') || lower.contains('keseluruhan') || lower.contains('semua');
    final category = isOverall
        ? null
        : _classifyCategory(input, TransactionType.expense, context.availableCategories);

    final now = DateTime.now();
    final draft = Budget(
      id: 'budget_draft_${DateTime.now().millisecondsSinceEpoch}',
      categoryId: isOverall ? 'overall' : category!.id,
      categoryName: isOverall ? 'Total Bulanan' : category!.name,
      limitAmount: amount,
      spentAmount: 0.0,
      month: now.month,
      year: now.year,
      isOverall: isOverall,
    );

    return AIMessage(
      id: _uuid.v4(),
      text: 'Saya telah menyiapkan draf anggaran **${isOverall ? "Total Bulanan" : category!.name}** sebesar **${CurrencyFormatter.format(amount)}** untuk bulan ini. Silakan tinjau dan konfirmasi:',
      isUser: false,
      draftBudget: draft,
      confidenceLevel: 'high',
    );
  }

  AIMessage _answerBudgetStatus(AIContext context) {
    if (context.budgets.isEmpty) {
      return AIMessage(
        id: _uuid.v4(),
        text: 'Anda belum memiliki anggaran aktif bulan ini. Anda dapat membuat anggaran dengan mengetik misalnya: *"Set budget makanan 1.5 juta"* atau *"Buat budget total 5 juta"*.',
        isUser: false,
      );
    }

    final overall = context.budgets.where((b) => b.isOverall).firstOrNull;
    final buffer = StringBuffer('📊 **Status Anggaran Bulan Ini:**\n\n');
    if (overall != null) {
      buffer.writeln('• **Total Bulanan:** Terpakai ${CurrencyFormatter.format(overall.spentAmount)} dari ${CurrencyFormatter.format(overall.limitAmount)} (${overall.percentUsed.toStringAsFixed(1)}%)');
      if (overall.isBurningTooFast) {
        buffer.writeln('  ⚠️ *Peringatan:* Laju pengeluaran Anda lebih cepat dari rencana harian.');
      }
    }
    for (final b in context.budgets.where((b) => !b.isOverall)) {
      buffer.writeln('• **${b.categoryName}:** ${CurrencyFormatter.format(b.spentAmount)} / ${CurrencyFormatter.format(b.limitAmount)} (${b.percentUsed.toStringAsFixed(0)}%)');
    }
    return AIMessage(id: _uuid.v4(), text: buffer.toString().trim(), isUser: false);
  }

  AIMessage? _handleSavingsGoalIntent(String input, AIContext context) {
    final lower = input.toLowerCase();
    final isCreation = lower.contains('target tabungan') ||
        lower.contains('target nabung') ||
        lower.contains('buat target') ||
        (lower.contains('mau nabung') && (lower.contains('buat') || lower.contains('untuk')));

    if (!isCreation) return null;

    final amount = _extractAmount(input);
    if (amount == null || amount <= 0) {
      return AIMessage(
        id: _uuid.v4(),
        text: 'Berapa target nominal yang ingin dicapai? Contoh: *"Mau nabung buat laptop 15 juta"*.',
        isUser: false,
      );
    }

    // Extract title
    String title = 'Target Tabungan';
    final targetMatch = RegExp(r'(?:buat|untuk|target|beli|nabung)\s+([A-Za-z0-9\s]+?)(?:\s+\d+|\s+sebesar|\s+sampai|$)', caseSensitive: false).firstMatch(input);
    if (targetMatch != null && targetMatch.group(1) != null) {
      var candidate = targetMatch.group(1)!.trim();
      candidate = candidate.replaceAll(RegExp(r'^(nabung|beli|buat|untuk|target)\s+', caseSensitive: false), '').trim();
      if (candidate.isNotEmpty && candidate.length > 2) {
        title = candidate[0].toUpperCase() + candidate.substring(1);
      }
    }

    // Target date estimation: default 6 months from now or end of year
    DateTime targetDate = DateTime.now().add(const Duration(days: 180));
    if (lower.contains('desember') || lower.contains('akhir tahun')) {
      targetDate = DateTime(DateTime.now().year, 12, 31);
    } else if (lower.contains('tahun depan')) {
      targetDate = DateTime(DateTime.now().year + 1, DateTime.now().month, DateTime.now().day);
    }

    // Find source (default: Tabungan or first available)
    final savingsSource = context.availableSources.firstWhere(
      (s) => s.name.toLowerCase().contains('tabungan'),
      orElse: () => context.availableSources.isNotEmpty
          ? context.availableSources.first
          : FundSource(id: 'src_savings', name: 'Tabungan', balance: 0.0),
    );

    final goal = SavingsGoal(
      id: 'goal_draft_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      targetAmount: amount,
      currentAmount: 0.0,
      sourceId: savingsSource.id,
      sourceName: savingsSource.name,
      deadline: targetDate,
      iconName: 'savings',
    );

    return AIMessage(
      id: _uuid.v4(),
      text: 'Saya telah menyiapkan draf target tabungan **$title** dengan target **${CurrencyFormatter.format(amount)}**. Silakan periksa dan simpan:',
      isUser: false,
      draftSavingsGoal: goal,
      confidenceLevel: 'high',
    );
  }

  AIMessage _answerFinancialHealth(AIContext context) {
    final health = FinancialHealthService.calculate(
      transactions: context.existingTransactions,
      sources: context.availableSources,
      budgets: context.budgets,
    );

    final buffer = StringBuffer('🩺 **Analisis Kesehatan Finansial ASTRACK:**\n\n');
    buffer.writeln('• **Skor Keseluruhan:** ${health.overallScore} / 100 (Grade ${health.grade.gradeLetter})');
    buffer.writeln('• **Savings Rate:** ${health.savingsRateScore.toStringAsFixed(0)}/35 poin (${(health.actualSavingsRate * 100).toStringAsFixed(1)}%)');
    buffer.writeln('• **Disiplin Anggaran:** ${health.budgetAdherenceScore.toStringAsFixed(0)}/30 poin');
    buffer.writeln('• **Dana Darurat:** ${health.emergencyBufferScore.toStringAsFixed(0)}/20 poin (${health.emergencyBufferMonths.toStringAsFixed(1)} bulan buffer)');
    buffer.writeln('• **Keteraturan Catat:** ${health.recordingRegularityScore.toStringAsFixed(0)}/15 poin\n');

    if (health.recommendations.isNotEmpty) {
      buffer.writeln('💡 **Rekomendasi Tindakan:**');
      for (final rec in health.recommendations) {
        buffer.writeln('• $rec');
      }
    }

    return AIMessage(id: _uuid.v4(), text: buffer.toString().trim(), isUser: false);
  }
}

class RemoteAIProvider implements AIProvider {
  final LocalRuleAIProvider _fallback = LocalRuleAIProvider();
  final String? apiKey;
  final http.Client _client;

  RemoteAIProvider({this.apiKey, http.Client? client}) : _client = client ?? http.Client();

  @override
  String get name => 'Cloud Neural Engine (Gemini / LLM)';

  @override
  Future<AIMessage> processInput({
    required String rawInput,
    required AIContext context,
    TransactionItem? pendingDraft,
  }) async {
    // 0. Security Guardrail: Prompt Injection Detection
    if (PromptInjectionDetector.isInjectionAttempt(rawInput)) {
      return AIMessage(
        id: const Uuid().v4(),
        text: '⚠️ **Instruksi Tidak Sah Terdeteksi**\n'
            'Asisten AI ASTRACK beroperasi dengan guardrail keamanan keuangan zero-trust. '
            'Saya tidak dapat menjalankan perintah manipulasi internal, bypass sistem, pembaruan saldo langsung tanpa ledger, atau pembocoran konfigurasi rahasia.',
        isUser: false,
        confidenceLevel: 'high',
      );
    }

    final key = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    // If no remote key configured, fallback smoothly to LocalRuleAIProvider
    if (key.isEmpty) {
      return _fallback.processInput(
        rawInput: rawInput,
        context: context,
        pendingDraft: pendingDraft,
      );
    }

    try {
      final endpoint = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key',
      );

      final prompt = '''
Anda adalah asisten keuangan ASTRACK. Analisis teks berikut dan berikan format JSON:
Input: "$rawInput"
Sumber dana tersedia: ${context.availableSources.map((s) => s.name).join(', ')}
Kategori tersedia: ${context.availableCategories.map((c) => c.name).join(', ')}

Keluarkan HANYA JSON tanpa markdown:
{
  "intent": "transaction" atau "query",
  "type": "expense" / "income" / "transfer" / "saving",
  "amount": number,
  "description": string,
  "category": string,
  "source": string atau null,
  "isAmbiguous": boolean
}
''';

      final response = await _client
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [{'text': prompt}]
                }
              ],
              'generationConfig': {'temperature': 0.1}
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final candidateText = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (candidateText != null) {
          final cleaned = candidateText.replaceAll('```json', '').replaceAll('```', '').trim();
          final parsedJson = jsonDecode(cleaned);
          if (parsedJson is Map<String, dynamic> && parsedJson['amount'] != null) {
            final double? amt = (parsedJson['amount'] as num?)?.toDouble();
            if (amt != null && amt > 0) {
              final srcName = parsedJson['source'] as String?;
              final source = srcName != null
                  ? context.availableSources.firstWhere(
                      (s) => s.name.toLowerCase() == srcName.toLowerCase(),
                      orElse: () => context.availableSources.first,
                    )
                  : (context.availableSources.isNotEmpty ? context.availableSources.first : null);

              final catName = parsedJson['category'] as String? ?? 'Pengeluaran';
              final cat = context.availableCategories.firstWhere(
                (c) => c.name.toLowerCase() == catName.toLowerCase(),
                orElse: () => context.availableCategories.first,
              );

              final draft = TransactionItem(
                id: 'tx_ai_${DateTime.now().millisecondsSinceEpoch}',
                type: parsedJson['type'] == 'income'
                    ? TransactionType.income
                    : parsedJson['type'] == 'transfer'
                        ? TransactionType.transfer
                        : parsedJson['type'] == 'saving'
                            ? TransactionType.saving
                            : TransactionType.expense,
                amount: amt,
                description: parsedJson['description'] as String? ?? rawInput,
                categoryId: cat.id,
                categoryName: cat.name,
                sourceId: source?.id ?? '',
                sourceName: source?.name ?? '',
                dateTime: DateTime.now(),
                notes: 'Draf otomatis dari Cloud AI (Gemini)',
              );

              return AIMessage(
                id: const Uuid().v4(),
                text: 'Cloud AI telah menyusun draf transaksi Anda. Silakan tinjau dan konfirmasi:',
                isUser: false,
                draftTransaction: draft,
                confidenceLevel: parsedJson['isAmbiguous'] == true ? 'medium' : 'high',
              );
            }
          }
        }
      }
      // On any HTTP failure (429, 500, etc) or unexpected JSON, fallback cleanly to local parser
      return await _fallback.processInput(rawInput: rawInput, context: context, pendingDraft: pendingDraft);
    } catch (_) {
      // Offline, timeout, or parsing error: graceful fallback
      return await _fallback.processInput(rawInput: rawInput, context: context, pendingDraft: pendingDraft);
    }
  }
}
