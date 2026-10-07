import 'package:flutter/material.dart';
import 'responsive_breakpoints.dart';

/// Container that prevents content from stretching excessively on large screens (Tablets, Desktop)
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ??
        context.responsiveValue<double>(
          compact: double.infinity,
          medium: AppBreakpoints.maxContentWidthTablet,
          expanded: AppBreakpoints.maxContentWidthWide,
        );

    Widget content = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: effectiveMaxWidth,
      ),
      child: child,
    );

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    return Align(
      alignment: alignment,
      child: content,
    );
  }
}
