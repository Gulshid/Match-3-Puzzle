import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:match3_puzzle/core/constants/design_constants.dart';
import 'package:match3_puzzle/features/game/domain/models/tile_model.dart';

/// Renders a single tile.
///
/// `size` is the tile's real on-screen pixel size, computed by
/// [GridWidget] from LayoutBuilder's constraints — the grid must divide
/// the *actual* available space evenly, so tile size is NOT derived from
/// ScreenUtil's .w/.h (that would fight with the grid's own layout).
/// ScreenUtil is still used here for the radius/icon so the *style*
/// scales consistently with the rest of the UI.
class TileWidget extends StatelessWidget {
  const TileWidget({super.key, required this.tile, required this.size});

  final TileModel tile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tile.type.color,
        borderRadius: BorderRadius.circular(BoardConfig.tileRadius.r),
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
    );
  }
}
