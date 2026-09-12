import 'dart:math';
import 'package:flutter/material.dart';

/// A one-shot radial sparkle burst, played once when a tile is matched.
/// Pure [CustomPainter] — no external particle package needed.
class MatchBurst extends StatefulWidget {
  const MatchBurst({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<MatchBurst> createState() => _MatchBurstState();
}

class _MatchBurstState extends State<MatchBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  late final List<double> _angles = List.generate(
    8,
    (i) => (2 * pi / 8) * i + Random(widget.color.value).nextDouble() * 0.4,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size * 2.4, widget.size * 2.4),
            painter: _BurstPainter(
              progress: _controller.value,
              color: widget.color,
              angles: _angles,
              baseRadius: widget.size * 0.5,
            ),
          );
        },
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.progress,
    required this.color,
    required this.angles,
    required this.baseRadius,
  });

  final double progress;
  final Color color;
  final List<double> angles;
  final double baseRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final eased = Curves.easeOut.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);

    for (final angle in angles) {
      final dist = baseRadius * (0.4 + eased * 1.3);
      final pos = center + Offset(cos(angle), sin(angle)) * dist;
      final r = (baseRadius * 0.16) * (1 - eased * 0.6);

      final paint = Paint()
        ..color = Color.lerp(color, Colors.white, 0.35)!.withOpacity(fade)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, max(r, 0.5), paint);
    }

    // Central flash ring.
    final ringPaint = Paint()
      ..color = color.withOpacity(fade * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, baseRadius * (0.6 + eased * 0.9), ringPaint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
