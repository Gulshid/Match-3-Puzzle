import 'package:flutter/material.dart';

/// Wraps [child] and plays a quick horizontal shake whenever [trigger]
/// changes (increment a counter to replay it — e.g. once per big combo).
///
/// Kept generic/reusable rather than baked into the board so it can also
/// wrap other things later (a HUD element on level-fail, etc).
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  late final Animation<double> _offset = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 2),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_offset.value, 0), child: child),
      child: widget.child,
    );
  }
}
