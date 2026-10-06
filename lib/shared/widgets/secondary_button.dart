import 'package:flutter/material.dart';
import '../../core/theme/astrack_theme_extension.dart';
import '../../core/theme/tokens/app_motion.dart';

/// Tactile Outlined / Secondary Button with Micro-Scale Press Feedback
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final IconData? icon;
  final double? width;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.icon,
    this.width,
    this.height = 50.0,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.astrackTheme;
    final isEnabled = widget.onPressed != null;
    final isReduceMotion = AppMotion.isReduceMotion(context);

    final scale = (_isPressed && isEnabled && !isReduceMotion)
        ? AppMotion.activeScale
        : 1.0;

    final baseColor = widget.isDestructive ? theme.expense : theme.textPrimary;
    final borderColor = widget.isDestructive
        ? theme.expense.withValues(alpha: 0.5)
        : theme.border;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: scale,
        duration: AppMotion.getDuration(context, AppMotion.tap),
        curve: AppMotion.enterCurve,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.isDestructive
                ? theme.expense.withValues(alpha: 0.08)
                : theme.surfaceSubtle,
            borderRadius: theme.buttonBorderRadius,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: baseColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: isEnabled ? baseColor : theme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
