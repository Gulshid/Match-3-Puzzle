import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/design_constants.dart';
import '../../domain/enums/tile_type.dart';
import '../../domain/models/tile_model.dart';

/// Renders a single tile.
///
/// `size` is the tile's real on-screen pixel size, computed by
/// [GridWidget] from LayoutBuilder's constraints (see that file's doc
/// comment for why). ScreenUtil is still used here for radius/border/
/// shadow so the *style* scales consistently across devices.
///
/// Phase 3 added: tap handling + a selection border.
/// Phase 4 added: a fade/shrink-out when [TileModel.isMatched] is true,
/// giving a (still basic — full polish is Phase 6) "matched" cue before
/// the tile is actually removed from the board.
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: tile.isMatched ? 0.0 : 1.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: tile.isMatched ? 0.4 : 1.0,
          curve: Curves.easeIn,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: tile.type.color,
              borderRadius: BorderRadius.circular(BoardConfig.tileRadius.r),
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
    );
  }
}
