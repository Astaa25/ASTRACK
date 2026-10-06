import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/astrack_theme_extension.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_radius.dart';

/// Formatted Numeric Input for Currency with Integer Precision
class AmountInput extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;
  final String? label;
  final bool autofocus;
  final List<int>? quickPresets;

  const AmountInput({
    super.key,
    this.initialValue = 0,
    required this.onChanged,
    this.label,
    this.autofocus = false,
    this.quickPresets = const [10000, 50000, 100000, 200000],
  });

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late TextEditingController _controller;
  int _currentAmount = 0;

  @override
  void initState() {
    super.initState();
    _currentAmount = widget.initialValue;
    _controller = TextEditingController(
      text: _currentAmount > 0 ? _formatNumber(_currentAmount) : '',
    );
  }

  @override
  void didUpdateWidget(covariant AmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && widget.initialValue != _currentAmount) {
      _currentAmount = widget.initialValue;
      _controller.text = _currentAmount > 0 ? _formatNumber(_currentAmount) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(int amount) {
    return AppLocalizations.formatCurrency(amount, symbol: '');
  }

  void _handleTextChange(String val) {
    final cleanDigits = val.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(cleanDigits) ?? 0;
    _currentAmount = parsed;
    widget.onChanged(parsed);

    final formatted = parsed > 0 ? _formatNumber(parsed) : '';
    if (_controller.text != formatted) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _addPreset(int preset) {
    final updated = _currentAmount + preset;
    _currentAmount = updated;
    _controller.text = _formatNumber(updated);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.astrackTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: AppRadius.lg,
            border: Border.all(color: theme.border, width: 1.5),
          ),
          child: Row(
            children: [
              Text(
                'Rp',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryEmerald,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTypography.financialHero(
                    fontSize: 26,
                    color: theme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: theme.textSecondary.withValues(alpha: 0.4),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: _handleTextChange,
                ),
              ),
              if (_currentAmount > 0)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: theme.textSecondary,
                  onPressed: () {
                    _currentAmount = 0;
                    _controller.clear();
                    widget.onChanged(0);
                  },
                ),
            ],
          ),
        ),
        if (widget.quickPresets != null && widget.quickPresets!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.quickPresets!.map((preset) {
                final label = '+${AppLocalizations.formatCompactCurrency(preset, symbol: '')}';
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ActionChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    backgroundColor: theme.surfaceSubtle,
                    side: BorderSide(color: theme.border, width: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.full),
                    onPressed: () => _addPreset(preset),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
