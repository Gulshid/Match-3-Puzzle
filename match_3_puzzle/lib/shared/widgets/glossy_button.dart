import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A chunky, glossy "candy" button with real pressed-depth: it sits on
/// a solid drop-shadow "base" color and squashes down onto it on tap,
/// like a physical arcade button. Includes a diagonal gloss highlight
/// for the 3D sheen.
class GlossyButton extends StatefulWidget {
  const GlossyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = const Color(0xFFFF5FA2),
    this.baseColor,
    this.height = 56,
    this.borderRadius = 20,
    this.depth = 6,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color? baseColor;
  final double height;
  final double borderRadius;
  final double depth;

  @override
  State<GlossyButton> createState() => _GlossyButtonState();
}

class _GlossyButtonState extends State<GlossyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final base = widget.baseColor ?? Color.lerp(widget.color, Colors.black, 0.35)!;
    final color = enabled ? widget.color : widget.color.withOpacity(0.45);
    final radius = BorderRadius.circular(widget.borderRadius);

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              HapticFeedback.lightImpact();
              widget.onPressed!.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        height: widget.height,
        padding: EdgeInsets.only(
          top: _pressed ? widget.depth : 0,
          bottom: _pressed ? 0 : widget.depth,
        ),
        decoration: BoxDecoration(
          color: enabled ? base : base.withOpacity(0.4),
          borderRadius: radius,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.white, 0.18)!,
                color,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Gloss highlight.
              Positioned(
                top: 3,
                left: widget.borderRadius * 0.6,
                right: widget.borderRadius * 0.6,
                child: Container(
                  height: widget.height * 0.28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Center(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}
