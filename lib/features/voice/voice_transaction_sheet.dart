import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/permission_service.dart';
import '../../models/transaction_item.dart';
import '../../providers/finance_provider.dart';
import '../../services/ai_service.dart';
import '../../services/speech/speech_service.dart';
import '../../core/widgets/app_button.dart';

enum VoiceState {
  idle,        // Belum mulai
  listening,   // Sedang "merekam" — user ketik atau pakai sampel
  processing,  // Memproses AI
  transcriptReady, // Draft siap dikonfirmasi
  permissionDenied,
  error,
}

class VoiceTransactionSheet extends StatefulWidget {
  const VoiceTransactionSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceTransactionSheet(),
    );
  }

  @override
  State<VoiceTransactionSheet> createState() => _VoiceTransactionSheetState();
}

class _VoiceTransactionSheetState extends State<VoiceTransactionSheet>
    with SingleTickerProviderStateMixin {
  VoiceState _state = VoiceState.idle;
  String _transcript = '';
  String _errorMessage = '';
  TransactionItem? _draft;
  late AnimationController _animController;

  // For manual input fallback (web/simulator)
  final TextEditingController _manualInputCtrl = TextEditingController();
  bool _showManualInput = false;
  bool _isSaving = false;
  final FocusNode _inputFocusNode = FocusNode();

  final List<String> _samplePhrases = [
    'Tadi makan ayam 18 ribu pakai uang jajan',
    'Kemarin dapat uang 500 ribu masuk uang jajan',
    'Beli bensin 25rb pakai uang jajan',
    'Simpan 100 ribu ke tabungan',
    'Bayar listrik 150 ribu dari tabungan',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    SpeechService.stopListening();
    _animController.dispose();
    _manualInputCtrl.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  // ── Start listening: check permission & activate Speech Recognition ──────
  Future<void> _startListening() async {
    final status = await PermissionService()
        .requestPermission(AstraPermissionType.microphone);
    if (status == AstraPermissionStatus.denied ||
        status == AstraPermissionStatus.permanentlyDenied) {
      setState(() {
        _state = VoiceState.permissionDenied;
        _errorMessage = 'Izin mikrofon diperlukan. Aktifkan di pengaturan browser / perangkat.';
      });
      return;
    }

    setState(() {
      _state = VoiceState.listening;
      _transcript = '';
      _draft = null;
      _showManualInput = false;
    });

    SpeechService.startListening(
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _transcript = text;
          _manualInputCtrl.text = text;
        });
      },
      onEnd: () {
        if (!mounted) return;
        if (_state == VoiceState.listening) {
          final recognized = _transcript.isNotEmpty ? _transcript : _manualInputCtrl.text.trim();
          if (recognized.isNotEmpty) {
            _onTranscriptReceived(recognized);
          }
        }
      },
      onError: (err) {
        debugPrint('Speech recognition error: $err');
      },
    );
  }

  // Called when user taps "Stop"
  void _stopListening() {
    SpeechService.stopListening();
    final text = _transcript.isNotEmpty ? _transcript : _manualInputCtrl.text.trim();
    if (text.isNotEmpty) {
      _onTranscriptReceived(text);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suara belum terdeteksi. Silakan bicara lagi atau ketik di kolom teks.'),
        duration: Duration(seconds: 2),
      ),
    );
    setState(() {
      _showManualInput = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _inputFocusNode.requestFocus();
    });
  }

  void _onTranscriptReceived(String text) async {
    SpeechService.stopListening();
    if (text.trim().isEmpty) return;
    _manualInputCtrl.clear();
    _inputFocusNode.unfocus();

    setState(() {
      _state = VoiceState.processing;
      _transcript = text.trim();
      _showManualInput = false;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final finance = context.read<FinanceProvider>();
    try {
      final aiResponse = await AIService.processInput(
        rawInput: _transcript,
        availableSources: finance.sources,
        availableCategories: finance.categories,
        existingTransactions: finance.transactions,
      );

      if (aiResponse.draftTransaction != null) {
        TransactionItem draft = aiResponse.draftTransaction!;
        
        // If user did NOT mention explicit time, ALWAYS ask them!
        if (!aiResponse.hasExplicitTime && mounted) {
          final confirmed = await _showDateTimeConfirmDialog(draft.dateTime);
          if (!mounted) return;
          if (confirmed != null) {
            draft = draft.copyWith(dateTime: confirmed);
          }
        }

        setState(() {
          _draft = draft;
          _state = VoiceState.transcriptReady;
        });
      } else {
        // Handoff to AI Chat Screen for Q&A or Clarifications
        Navigator.of(context).pop(_transcript); // Close voice sheet and return text
      }
    } catch (e) {
      setState(() {
        _state = VoiceState.error;
        _errorMessage = 'Gagal memproses: $e';
      });
    }
  }

  /// Shows a dialog asking the user to confirm / adjust the transaction date+time
  Future<DateTime?> _showDateTimeConfirmDialog(DateTime current) async {
    DateTime selected = current;
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
        return StatefulBuilder(
          builder: (sCtx, setS) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.access_time_rounded, color: primary, size: 22),
                const SizedBox(width: 8),
                const Text('Kapan transaksi ini?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Anda tidak menyebutkan waktu. Kapan transaksi ini terjadi?',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                // Quick options
                ...([
                  ('Sekarang', DateTime.now()),
                  ('Tadi (1 jam lalu)', DateTime.now().subtract(const Duration(hours: 1))),
                  ('Kemarin', DateTime.now().subtract(const Duration(days: 1))),
                  ('2 Hari Lalu', DateTime.now().subtract(const Duration(days: 2))),
                ]).map((opt) {
                  final isSelected = selected.day == opt.$2.day &&
                      selected.hour == opt.$2.hour;
                  return GestureDetector(
                    onTap: () => setS(() => selected = opt.$2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primary.withAlpha(20) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.radio_button_checked_rounded,
                              color: isSelected ? primary : Colors.grey, size: 18),
                          const SizedBox(width: 10),
                          Text(opt.$1,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? primary : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              )),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(current),
                child: const Text('Lewati'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(ctx).pop(selected),
                child: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmAndSave() {
    if (_draft == null) return;
    final finance = context.read<FinanceProvider>();
    
    setState(() => _isSaving = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      finance.addTransaction(_draft!);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Transaksi "${_draft!.description}" berhasil disimpan lewat suara.')),
            ],
          ),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  void _resetToIdle() {
    _manualInputCtrl.clear();
    _inputFocusNode.unfocus();
    setState(() {
      _state = VoiceState.idle;
      _transcript = '';
      _draft = null;
      _showManualInput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.darkCard : AppColors.lightCard;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.mic_rounded, color: primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Input Suara',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Plus Jakarta Sans',
                  color: primaryText,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close_rounded, color: secText),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Main state widget ──────────────────────────────────────────
          _buildStateWidget(isDark, primary, primaryText, secText, border),

          // ── Sample phrases — only in idle & listening ──────────────────
          if (_state == VoiceState.idle || _state == VoiceState.listening) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Atau ketuk contoh kalimat:',
                style: TextStyle(fontSize: 12, color: secText, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _samplePhrases.map((phrase) => GestureDetector(
                onTap: () => _onTranscriptReceived(phrase),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withAlpha(60)),
                  ),
                  child: Text(
                    phrase,
                    style: TextStyle(fontSize: 11.5, color: primary, fontWeight: FontWeight.w500),
                  ),
                ),
              )).toList(),
            ),
          ],

          // ── Confirm card ───────────────────────────────────────────────
          if (_state == VoiceState.transcriptReady && _draft != null) ...[
            const SizedBox(height: 14),
            _buildDraftCard(isDark, primary, primaryText, secText, border),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Ulangi'),
                    onPressed: _resetToIdle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secText,
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: 'Simpan',
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _confirmAndSave,
                    backgroundColor: primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStateWidget(bool isDark, Color primary, Color primaryText, Color secText, Color border) {
    switch (_state) {
      // ── IDLE: big mic button ───────────────────────────────────────────
      case VoiceState.idle:
        return Column(
          children: [
            GestureDetector(
              onTap: _startListening,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primary, primary.withAlpha(200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withAlpha(80),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 42),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ketuk untuk mulai bicara',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
            ),
            const SizedBox(height: 3),
            Text(
              'Atau ketuk salah satu contoh kalimat di bawah',
              style: TextStyle(fontSize: 12, color: secText),
            ),
          ],
        );

      // ── LISTENING: animated mic + manual text input ────────────────────
      case VoiceState.listening:
        return Column(
          children: [
            // Pulsing mic — tap to stop
            GestureDetector(
              onTap: _stopListening,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (_, __) => Container(
                  width: 86 + (_animController.value * 18),
                  height: 86 + (_animController.value * 18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.expense,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.expense.withAlpha(100),
                        blurRadius: 24 * _animController.value,
                        spreadRadius: 8 * _animController.value,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.stop_rounded, color: Colors.white, size: 38),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sedang mendengarkan…',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.expense),
            ),
            const SizedBox(height: 4),
            Text(
              'Bicara sekarang, lalu ketuk ikon merah untuk berhenti & proses',
              style: TextStyle(fontSize: 12, color: secText),
            ),
            if (_transcript.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primary.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded, color: primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"$_transcript"',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Manual text input (web/simulator fallback)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevatedCard : const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _showManualInput ? primary : border,
                  width: _showManualInput ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualInputCtrl,
                      focusNode: _inputFocusNode,
                      autofocus: _showManualInput,
                      style: TextStyle(color: primaryText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _showManualInput
                            ? 'Ketik deskripsi transaksi (contoh: makan siang 25rb)'
                            : 'Atau ketik transaksi di sini…',
                        hintStyle: TextStyle(color: secText, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: _onTranscriptReceived,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send_rounded, color: primary),
                    onPressed: () {
                      final text = _manualInputCtrl.text.trim();
                      if (text.isNotEmpty) _onTranscriptReceived(text);
                    },
                  ),
                ],
              ),
            ),
            if (_showManualInput)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Ketik keterangan transaksi lalu kirim ↑',
                  style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        );

      // ── PROCESSING ─────────────────────────────────────────────────────
      case VoiceState.processing:
        return Column(
          children: [
            CircularProgressIndicator(color: primary, strokeWidth: 3),
            const SizedBox(height: 14),
            Text('AI sedang memproses…',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText)),
            const SizedBox(height: 6),
            if (_transcript.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '"$_transcript"',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: primary),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );

      // ── TRANSCRIPT READY: just show the snippet, card shown separately ─
      case VoiceState.transcriptReady:
        return Column(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.income, size: 40),
            const SizedBox(height: 8),
            Text('Transaksi berhasil dikenali!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.income)),
            const SizedBox(height: 4),
            Text('"$_transcript"',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: secText),
                textAlign: TextAlign.center),
          ],
        );

      // ── ERROR / PERMISSION DENIED ──────────────────────────────────────
      case VoiceState.error:
      case VoiceState.permissionDenied:
        return Column(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 48),
            const SizedBox(height: 10),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: primaryText)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi'),
              onPressed: _resetToIdle,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildDraftCard(bool isDark, Color primary, Color primaryText, Color secText, Color border) {
    final isIncome = _draft!.type == TransactionType.income;
    final typeColor = isIncome ? AppColors.income : AppColors.expense;
    final typeLabel = isIncome ? 'Pemasukan' : 'Pengeluaran';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedCard : const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withAlpha(80), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(typeLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: typeColor)),
              ),
              const Spacer(),
              Text(
                'Rp ${_draft!.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_draft!.description,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText)),
          const SizedBox(height: 4),
          Text(
            '${_draft!.categoryName}  •  ${_draft!.sourceName}',
            style: TextStyle(fontSize: 12, color: secText),
          ),
        ],
      ),
    );
  }
}
