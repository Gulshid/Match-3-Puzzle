import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A slowly-drifting, softly-glowing gradient background used behind
/// every screen. Cheap (a handful of blurred circles animating on a
/// single [AnimationController]) but reads as a premium, alive backdrop
/// instead of a flat color.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    super.key,
    this.child,
    this.extraVibrant = false,
  });

  final Widget? child;

  /// Slightly stronger blobs + faster motion — used on the game board
  /// screen so it feels a touch more energetic than menus.
  final bool extraVibrant;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.extraVibrant ? 14 : 22),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.skyDark : AppColors.skyLight;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: base,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _BlobPainter(
                t: _controller.value,
                isDark: isDark,
                vibrant: widget.extraVibrant,
              ),
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.t, required this.isDark, required this.vibrant});

  final double t;
  final bool isDark;
  final bool vibrant;

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      (AppColors.candyPink, 0.0, 0.20, 0.18),
      (AppColors.candyBlue, 0.33, 0.75, 0.16),
      (AppColors.candyMint, 0.66, 0.45, 0.14),
    ];

    for (final (color, phase, sizeFactor, opacity) in blobs) {
      final angle = 2 * pi * ((t + phase) % 1.0);
      final cx = size.width * (0.5 + 0.38 * cos(angle));
      final cy = size.height * (0.5 + 0.32 * sin(angle * 1.3));
      final radius = size.shortestSide * sizeFactor * (vibrant ? 1.15 : 1.0);

      final paint = Paint()
        ..color = color.withOpacity(isDark ? opacity * 0.9 : opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.55);

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.t != t;
}
