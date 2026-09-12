import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/design_constants.dart';
import '../../domain/enums/tile_type.dart';
import '../../domain/models/level_config.dart';
import '../../domain/models/tile_model.dart';

/// Renders a single tile, including Phase 9 special-tile visuals and
/// Phase 10 obstacle overlays.
///
/// Special tiles show:
/// - A gradient shimmer on the tile body.
/// - An overlay icon (stripes / ∞ / blur) indicating the special type.
/// - A white flash [AnimatedOpacity] when [isActivating] is true.
///
/// Obstacle tiles (ice / crate) show an overlay on top of the normal
/// tile — ice as a translucent frosted layer, crates as a solid brown
/// panel (tile is null for crates, so we render a crate-only widget).
class TileWidget extends StatelessWidget {
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

  /// Phase 9: true for the one frame when a special is about to fire.
  final bool isActivating;

  /// Phase 10: non-null when an obstacle overlays this cell.
  final ObstacleType? obstacleType;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final matched = tile.isMatched;
    final special = tile.specialType;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
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
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tile.type.color.withOpacity(0.45),
                ),
              ),
            ),

            // ── Tile body ──────────────────────────────────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: matched ? 0.0 : 1.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: matched ? 0.3 : 1.0,
                curve: matched ? Curves.easeInBack : Curves.easeOutBack,
                child: _TileBody(
                  tile: tile,
                  size: size,
                  isSelected: isSelected,
                  special: special,
                ),
              ),
            ),

            // ── Phase 10: Ice overlay ──────────────────────────────
            if (obstacleType == ObstacleType.ice && !matched)
              _IceOverlay(size: size),

            // ── Phase 9: Activation flash ──────────────────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 80),
              opacity: isActivating ? 1.0 : 0.0,
              child: Container(
                width: size,
                height: size,
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

/// The tile's main coloured body (handles normal + special appearance).
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Phase 9: specials use a gradient instead of flat color.
        gradient: special != null
            ? LinearGradient(
                colors: [
                  tile.type.color,
                  tile.type.color.withOpacity(0.6),
                  Colors.white.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: special == null ? tile.type.color : null,
        borderRadius: radius,
        border: isSelected
            ? Border.all(color: Colors.white, width: 3.r)
            : special != null
                ? Border.all(color: Colors.white.withOpacity(0.6), width: 1.5.r)
                : null,
        boxShadow: [
          BoxShadow(
            color: special != null
                ? tile.type.color.withOpacity(0.5)
                : Colors.black.withOpacity(0.15),
            blurRadius: special != null ? 8.r : 3.r,
            spreadRadius: special != null ? 1.r : 0,
            offset: Offset(0, 2.r),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Normal icon.
          Icon(
            tile.type.icon,
            color: Colors.white,
            size: size * 0.45,
          ),
          // Phase 9: special overlay icon.
          if (special != null)
            Positioned(
              right: 3.r,
              bottom: 3.r,
              child: Icon(
                special!.overlayIcon,
                color: Colors.white.withOpacity(0.9),
                size: size * 0.28,
              ),
            ),
        ],
      ),
    );
  }
}

/// Phase 10: Frosted ice overlay rendered on top of the tile body.
class _IceOverlay extends StatelessWidget {
  const _IceOverlay({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.lightBlue.withOpacity(0.35),
        borderRadius: BorderRadius.circular(BoardConfig.tileRadius.r),
        border:
            Border.all(color: Colors.lightBlueAccent.withOpacity(0.6), width: 1.5.r),
      ),
      child: Icon(
        Icons.ac_unit,
        color: Colors.white.withOpacity(0.7),
        size: size * 0.4,
      ),
    );
  }
}

/// Phase 10: Standalone crate cell widget (no underlying tile).
class CrateTileWidget extends StatelessWidget {
  const CrateTileWidget({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF8B6914),
        borderRadius: BorderRadius.circular(BoardConfig.tileRadius.r),
        border: Border.all(color: const Color(0xFF5C4209), width: 2.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3.r,
            offset: Offset(0, 2.r),
          ),
        ],
      ),
      child: Icon(
        Icons.inventory_2,
        color: Colors.white.withOpacity(0.85),
        size: size * 0.45,
      ),
    );
  }
}
