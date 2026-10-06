import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final double borderRadius;
  final bool hasShadow;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.borderRadius = 20,
    this.hasShadow = true,
    this.border,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _animController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _animController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null || widget.onLongPress != null) {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = widget.backgroundColor ?? (isDark ? const Color(0xFF0D1B15) : Colors.white);
    final defaultBorder = widget.border ??
        Border.all(
          color: isDark ? const Color(0xFF1D3329) : const Color(0xFFE6EBE9),
          width: 0.5,
        );

    final shadow = widget.hasShadow
        ? [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFF000000).withOpacity(0.02),
              blurRadius: 24,
              offset: const Offset(0, 12),
            )
          ]
        : null;

    Widget cardContent = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Container(
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: defaultBg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: defaultBorder,
          boxShadow: shadow,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress?.call();
        },
        child: cardContent,
      );
    }

    return cardContent;
  }
}
