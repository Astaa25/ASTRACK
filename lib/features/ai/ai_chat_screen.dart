import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/ai_message.dart';
import '../../models/transaction_item.dart';
import '../../services/ai_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../voice/voice_transaction_sheet.dart';

class AIChatScreen extends StatefulWidget {
  final String? initialQuery;
  const AIChatScreen({super.key, this.initialQuery});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<AIMessage> _messages = [];
  bool _isProcessing = false;
  bool _isListeningVoice = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      AIMessage(
        id: const Uuid().v4(),
        text: 'Halo! Saya asisten finansial ASTRACK ✨\n\n'
            'Ceritakan transaksi Anda dengan bahasa santai, misalnya:\n'
            '• "Tadi pagi beli nasi 12 ribu pakai uang jajan"\n'
            '• "Bulan ini saya sudah habis berapa?"\n'
            '• "Kalau saya tambah pengeluaran 100 ribu hari ini, saldo Uang Jajan jadi berapa?"',
        isUser: false,
      ),
    );

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery);
      });
    }
  }

  void _sendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _textController.text.trim();
    if (text.isEmpty) return;

    if (predefinedText == null) {
      _textController.clear();
    }

    final userMsg = AIMessage(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
    );

    setState(() {
      _messages.add(userMsg);
      _isProcessing = true;
    });

    _scrollToBottom();

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final response = await AIService.processInput(
      rawInput: text,
      availableSources: finance.sources,
      availableCategories: finance.categories,
      existingTransactions: finance.transactions,
      budgets: finance.budgets,
      savingsGoals: finance.savingsGoals,
    );

    if (!mounted) return;

    setState(() {
      _messages.add(response);
      _isProcessing = false;
    });

    _scrollToBottom();
  }

  void _simulateVoiceInput() async {
    final transcript = await VoiceTransactionSheet.show(context);
    if (transcript != null && transcript.isNotEmpty && mounted) {
      _sendMessage(transcript);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _confirmAndSaveTransaction(AIMessage msg) {
    if (msg.draftTransaction == null) return;
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    finance.addTransaction(msg.draftTransaction!);

    setState(() {
      final idx = _messages.indexOf(msg);
      if (idx != -1) {
        _messages[idx] = msg.copyWith(isConfirmed: true);
      }
      _messages.add(
        AIMessage(
          id: const Uuid().v4(),
          text: '✓ **Transaksi berhasil disimpan!** Saldo ${msg.draftTransaction!.sourceName} telah diperbarui.',
          isUser: false,
        ),
      );
    });

    _scrollToBottom();
  }

  void _confirmAndSaveBudget(AIMessage msg) {
    if (msg.draftBudget == null) return;
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    finance.setBudget(msg.draftBudget!);

    setState(() {
      final idx = _messages.indexOf(msg);
      if (idx != -1) {
        _messages[idx] = msg.copyWith(isConfirmed: true);
      }
      _messages.add(
        AIMessage(
          id: const Uuid().v4(),
          text: '✓ **Anggaran berhasil ditetapkan!** Batas ${msg.draftBudget!.categoryName} sebesar ${CurrencyFormatter.format(msg.draftBudget!.limitAmount)} untuk bulan ini telah aktif.',
          isUser: false,
        ),
      );
    });

    _scrollToBottom();
  }

  void _confirmAndSaveSavingsGoal(AIMessage msg) {
    if (msg.draftSavingsGoal == null) return;
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    finance.addSavingsGoal(msg.draftSavingsGoal!);

    setState(() {
      final idx = _messages.indexOf(msg);
      if (idx != -1) {
        _messages[idx] = msg.copyWith(isConfirmed: true);
      }
      _messages.add(
        AIMessage(
          id: const Uuid().v4(),
          text: '✓ **Target tabungan berhasil dibuat!** Target "${msg.draftSavingsGoal!.name}" (${CurrencyFormatter.format(msg.draftSavingsGoal!.targetAmount)}) telah ditambahkan.',
          isUser: false,
        ),
      );
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASTRACK AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Natural Language & Insights',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageItem(msg, isDark);
                },
              ),
            ),

            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                    const SizedBox(width: 8),
                    Text(
                      '✨ ASTRACK AI sedang menganalisis...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                children: [
                  // Indonesian Voice Input Button
                  IconButton(
                    icon: Icon(
                      _isListeningVoice ? Icons.mic : Icons.mic_none_rounded,
                      color: _isListeningVoice ? AppColors.expense : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                    ),
                    onPressed: _simulateVoiceInput,
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ketik apa saja...',
                        filled: true,
                        fillColor: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(AIMessage msg, bool isDark) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkElevatedCard : AppColors.lightLightGreen,
            borderRadius: BorderRadius.circular(18).copyWith(bottomRight: const Radius.circular(4)),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      );
    }

    // AI message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(4)),
                border: Border.all(
                  color: msg.isSimulation
                      ? (isDark ? AppColors.warningDark : AppColors.warning)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppColors.darkPrimary.withValues(alpha: 0.06),
                          blurRadius: 16,
                        )
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      height: 1.45,
                    ),
                  ),

                  // Draft Transaction Confirmation Card
                  if (msg.draftTransaction != null && !msg.isConfirmed) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkElevatedCard : AppColors.lightSoftGreen,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: msg.isDuplicateWarning
                              ? AppColors.warning
                              : (isDark ? AppColors.darkPrimary.withValues(alpha: 0.4) : AppColors.lightPrimary),
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
                                  msg.draftTransaction!.description,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(msg.draftTransaction!.amount),
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: msg.draftTransaction!.type == TransactionType.income
                                      ? AppColors.income
                                      : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${msg.draftTransaction!.categoryName} • ${msg.draftTransaction!.sourceName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() => _messages.remove(msg));
                                },
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                onPressed: () => _confirmAndSaveTransaction(msg),
                                child: Text(msg.isDuplicateWarning ? 'Tetap Simpan' : 'Simpan Transaksi'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Draft Budget Confirmation Card
                  if (msg.draftBudget != null && !msg.isConfirmed) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkElevatedCard : AppColors.lightSoftGreen,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.4) : AppColors.lightPrimary,
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
                                  'Anggaran: ${msg.draftBudget!.categoryName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(msg.draftBudget!.limitAmount),
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bulan: ${msg.draftBudget!.month}/${msg.draftBudget!.year} • ${msg.draftBudget!.isOverall ? "Total Bulanan" : "Per Kategori"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() => _messages.remove(msg));
                                },
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                onPressed: () => _confirmAndSaveBudget(msg),
                                child: const Text('Simpan Anggaran'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Draft Savings Goal Confirmation Card
                  if (msg.draftSavingsGoal != null && !msg.isConfirmed) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkElevatedCard : AppColors.lightSoftGreen,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.4) : AppColors.lightPrimary,
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
                                  'Target: ${msg.draftSavingsGoal!.name}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(msg.draftSavingsGoal!.targetAmount),
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.income,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Target Waktu: ${msg.draftSavingsGoal!.deadline != null ? "${msg.draftSavingsGoal!.deadline!.day}/${msg.draftSavingsGoal!.deadline!.month}/${msg.draftSavingsGoal!.deadline!.year}" : "Fleksibel"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() => _messages.remove(msg));
                                },
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                onPressed: () => _confirmAndSaveSavingsGoal(msg),
                                child: const Text('Simpan Target'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Clarification Quick Choice Buttons
                  if (msg.clarificationOptions != null && msg.clarificationOptions!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: msg.clarificationOptions!.map((opt) {
                        return ActionChip(
                          label: Text(opt),
                          backgroundColor: isDark ? AppColors.darkElevatedCard : AppColors.lightSoftGreen,
                          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          onPressed: () => _sendMessage(opt),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
