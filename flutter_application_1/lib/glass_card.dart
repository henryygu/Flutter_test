import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final Color? color;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 24,
    this.opacity = 0.08,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.color,
    this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? Colors.white : Colors.black);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor.withOpacity(opacity),
            borderRadius: borderRadius,
            border:
                border ??
                Border.all(color: bgColor.withOpacity(0.12), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
