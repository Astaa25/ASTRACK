import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/liquid_loader.dart';

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isFullWidth = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      _scaleController.reverse();
      HapticFeedback.lightImpact();
      widget.onPressed();
    }
  }

  void _handleTapCancel() {
    if (!widget.isLoading) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bg = widget.backgroundColor ?? (isDark ? const Color(0xFF087F5B) : const Color(0xFF087F5B));
    final fg = widget.textColor ?? Colors.white;

    Widget buttonContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      width: widget.isLoading ? 52 : (widget.isFullWidth ? double.infinity : null),
      padding: widget.isLoading ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: widget.isLoading ? bg.withOpacity(0.8) : bg,
        borderRadius: BorderRadius.circular(widget.isLoading ? 26 : 16),
        boxShadow: widget.isLoading
            ? []
            : [
                BoxShadow(
                  color: bg.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      alignment: Alignment.center,
      child: widget.isLoading
          ? AstrackLiquidLoader.compact(
              size: 22,
              accentColor: fg,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: buttonContent,
      ),
    );
  }
}
