import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:match3_puzzle/core/constants/design_constants.dart';
import 'package:match3_puzzle/features/game/application/providers/board_provider.dart';
import 'package:match3_puzzle/features/game/presentation/widgets/tile_widget.dart';

/// Renders the whole board.
///
/// Uses its own inner [LayoutBuilder] (separate from the app-level one in
/// main.dart, which only picks the ScreenUtil design size) to fit a square
/// grid of tiles into whatever space its parent gives it — phone, tablet,
/// split-screen, or desktop window, all handled the same way.
class GridWidget extends ConsumerWidget {
  const GridWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(boardProvider);
    final spacing = BoardConfig.tileSpacing.w;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHSpacing = spacing * (board.cols - 1);
        final totalVSpacing = spacing * (board.rows - 1);

        final maxTileWidth =
            (constraints.maxWidth - totalHSpacing) / board.cols;
        final maxTileHeight =
            (constraints.maxHeight - totalVSpacing) / board.rows;

        // Square tiles: use whichever dimension is tighter.
        final tileSize = maxTileWidth < maxTileHeight
            ? maxTileWidth
            : maxTileHeight;

        final boardWidth = board.cols * tileSize + totalHSpacing;
        final boardHeight = board.rows * tileSize + totalVSpacing;

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Stack(
              children: [
                for (final row in board.grid)
                  for (final tile in row)
                    Positioned(
                      left: tile.col * (tileSize + spacing),
                      top: tile.row * (tileSize + spacing),
                      width: tileSize,
                      height: tileSize,
                      // Keyed by tile.id (not row/col) so that once
                      // swapping/falling animate in Phase 3/6,
                      // AnimatedPositioned can track this exact tile as
                      // its row/col change.
                      child: KeyedSubtree(
                        key: ValueKey(tile.id),
                        child: TileWidget(tile: tile, size: tileSize),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
