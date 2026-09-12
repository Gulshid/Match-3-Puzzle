import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/design_constants.dart';
import '../../../../shared/widgets/match_burst.dart';
import '../../domain/enums/tile_type.dart';
import '../../domain/models/level_config.dart';
import '../../domain/models/tile_model.dart';

/// Renders a single tile with real 3D depth: a glossy bevelled body,
/// a perspective flip-in on spawn, a perspective "lift" when selected,
/// and a spin-away + sparkle burst when matched.
class TileWidget extends StatefulWidget {
  const TileWidget({
    super.key,
    required this.tile,
    required this.size,
    this.isSelected = false,
    this.isActivating = false,
    this.obstacleType,
    this.onTap,
  });

  final TileModel tile;
  final double size;
  final bool isSelected;

  /// True for the one frame when a special is about to fire.
  final bool isActivating;

  /// Non-null when an obstacle overlays this cell.
  final ObstacleType? obstacleType;

  final VoidCallback? onTap;

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  // Plays once when this widget is first mounted — i.e. whenever a
  // genuinely new tile spawns (grid_widget keys tiles by id, so a
  // fresh id means a fresh State here). Real 3D perspective flip.
  late final AnimationController _spawnController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  late final Animation<double> _spawnCurve = CurvedAnimation(
    parent: _spawnController,
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _spawnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matched = widget.tile.isMatched;
    final special = widget.tile.specialType;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── Burst ring (matched animation) ─────────────────────
            AnimatedScale(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              scale: matched ? 1.8 : 0.0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.tile.type.color.withOpacity(0.45),
                ),
              ),
            ),

            // ── Sparkle particle burst ──────────────────────────────
            if (matched) MatchBurst(color: widget.tile.type.color, size: widget.size),

            // ── Tile body: 3D spawn-flip + lift + matched spin-out ──
            AnimatedBuilder(
              animation: _spawnCurve,
              builder: (context, child) {
                final spawnT = _spawnCurve.value.clamp(0.0, 1.0);
                final flipAngle = (1 - spawnT) * pi; // spin in on Y axis
                final liftScale = widget.isSelected ? 1.12 : 1.0;

                final matrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.0012) // perspective
                  ..rotateX(widget.isSelected ? -0.16 : 0.0)
                  ..rotateY(flipAngle)
                  ..scale(liftScale);

                return Transform(
                  alignment: Alignment.center,
                  transform: matrix,
                  child: child,
                );
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: matched ? 0.0 : 1.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  scale: matched ? 0.2 : 1.0,
                  curve: matched ? Curves.easeInBack : Curves.easeOutBack,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 260),
                    turns: matched ? 0.4 : 0.0,
                    curve: Curves.easeIn,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        boxShadow: widget.isSelected
                            ? [
                                BoxShadow(
                                  color: widget.tile.type.color
                                      .withOpacity(0.55),
                                  blurRadius: 18.r,
                                  spreadRadius: 1.r,
                                  offset: Offset(0, 8.r),
                                ),
                              ]
                            : const [],
                      ),
                      child: _TileBody(
                        tile: widget.tile,
                        size: widget.size,
                        isSelected: widget.isSelected,
                        special: special,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Ice overlay ──────────────────────────────────────────
            if (widget.obstacleType == ObstacleType.ice && !matched)
              _IceOverlay(size: widget.size),

            // ── Activation flash ──────────────────────────────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 80),
              opacity: widget.isActivating ? 1.0 : 0.0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius:
                      BorderRadius.circular(BoardConfig.tileRadius.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tile's main coloured body — glossy bevelled "candy" look, built
/// from a diagonal highlight gradient, a darker base shadow layer, and
/// an inner rim light so it reads as a physical, lit 3D piece.
class _TileBody extends StatelessWidget {
  const _TileBody({
    required this.tile,
    required this.size,
    required this.isSelected,
    required this.special,
  });

  final TileModel tile;
  final double size;
  final bool isSelected;
  final SpecialTileType? special;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(BoardConfig.tileRadius.r);
    final baseColor = tile.type.color;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: Color.lerp(baseColor, Colors.black, 0.35),
        borderRadius: radius,
        border: isSelected
            ? Border.all(color: Colors.white, width: 3.r)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 6.r,
            offset: Offset(0, 4.r),
          ),
        ],
      ),
      // Bevelled glossy face, inset slightly to reveal the darker base
      // as a rim — this is what sells the 3D "candy piece" look.
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BoardConfig.tileRadius.r * 0.85),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: special != null
                ? [
                    Color.lerp(baseColor, Colors.white, 0.55)!,
                    baseColor,
                    Color.lerp(baseColor, Colors.black, 0.15)!,
                  ]
                : [
                    Color.lerp(baseColor, Colors.white, 0.32)!,
                    baseColor,
                  ],
          ),
          border: special != null
              ? Border.all(color: Colors.white.withOpacity(0.7), width: 1.5.r)
              : null,
          boxShadow: special != null
              ? [
                  BoxShadow(
                    color: baseColor.withOpacity(0.6),
                    blurRadius: 10.r,
                    spreadRadius: 1.r,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gloss highlight streak.
            Positioned(
              top: size * 0.08,
              left: size * 0.14,
              child: Container(
                width: size * 0.4,
                height: size * 0.14,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Icon(
              tile.type.icon,
              color: Colors.white,
              size: size * 0.44,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            if (special != null)
              Positioned(
                right: 3.r,
                bottom: 3.r,
                child: Icon(
                  special!.overlayIcon,
                  color: Colors.white.withOpacity(0.95),
                  size: size * 0.26,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Frosted ice overlay rendered on top of the tile body.
class _IceOverlay extends StatelessWidget {
  const _IceOverlay({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.lightBlue.withOpacity(0.45),
            Colors.white.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(BoardConfig.tileRadius.r),
        border: Border.all(
            color: Colors.lightBlueAccent.withOpacity(0.7), width: 1.5.r),
      ),
      child: Icon(
        Icons.ac_unit,
        color: Colors.white.withOpacity(0.85),
        size: size * 0.4,
      ),
    );
  }
}

/// Standalone crate cell widget (no underlying tile) — wood-grain style
/// gradient panel with a hinge-bolt detail for a bit of extra depth.
class CrateTileWidget extends StatelessWidget {
  const CrateTileWidget({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFAD7A28), Color(0xFF7A4F0F)],
        ),
        borderRadius: BorderRadius.circular(BoardConfig.tileRadius.r),
        border: Border.all(color: const Color(0xFF4A3108), width: 2.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 5.r,
            offset: Offset(0, 3.r),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            color: Colors.white.withOpacity(0.9),
            size: size * 0.45,
          ),
          for (final align in const [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(
              alignment: align,
              child: Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: Container(
                  width: size * 0.06,
                  height: size * 0.06,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
