import 'package:flutter/material.dart';

/// Wraps [child] with a bouncy 3D "pop into existence" entrance:
/// scales up from nothing with a slight perspective tilt that settles
/// flat, using an elastic curve for a satisfying overshoot.
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value.clamp(0.0, 1.4);
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX((1 - t.clamp(0.0, 1.0)) * -0.6)
          ..scale(t.clamp(0.0, 1.4));
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
