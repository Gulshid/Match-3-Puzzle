import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Frosted glass panel: blurred backdrop + translucent fill + soft
/// border + drop shadow. The base building block for HUD chips, menu
/// cards, and overlays throughout the app.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.opacity = 0.16,
    this.blur = 18,
    this.border = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double opacity;
  final double blur;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderRadius = BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glass(brightness, opacity: opacity),
            borderRadius: borderRadius,
            border: border
                ? Border.all(color: AppColors.glassBorder(brightness), width: 1.2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
