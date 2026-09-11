import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/design_constants.dart';
import '../../domain/enums/tile_type.dart';
import '../../domain/models/tile_model.dart';

/// Renders a single tile.
///
/// `size` is the tile's real on-screen pixel size, computed by
/// [GridWidget] from LayoutBuilder's constraints. ScreenUtil is still
/// used here for radius/border/shadow so the *style* scales
/// consistently across devices.
///
/// Phase 3: tap handling + a selection border.
/// Phase 6: a small colored "burst" ring behind the tile plus a snappier
/// pop-out curve when [TileModel.isMatched] flips true, instead of a
/// plain linear fade/shrink.
class TileWidget extends StatelessWidget {
  const TileWidget({
    super.key,
    required this.tile,
    required this.size,
    this.isSelected = false,
    this.onTap,
  });

  final TileModel tile;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final matched = tile.isMatched;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Cheap "burst" substitute for a particle effect: a
            // translucent ring that scales up from nothing the instant
            // a match is flagged. It reads as an outward pop because the
            // tile itself is removed from the tree shortly after
            // (matched -> cleared, ~380ms), so the ring never lingers.
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
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: matched ? 0.0 : 1.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: matched ? 0.3 : 1.0,
                curve: matched ? Curves.easeInBack : Curves.easeOutBack,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: tile.type.color,
                    borderRadius:
                        BorderRadius.circular(BoardConfig.tileRadius.r),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3.r)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 3.r,
                        offset: Offset(0, 2.r),
                      ),
                    ],
                  ),
                  child: Icon(
                    tile.type.icon,
                    color: Colors.white,
                    size: size * 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
