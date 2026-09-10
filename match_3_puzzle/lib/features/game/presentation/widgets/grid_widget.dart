import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/design_constants.dart';
import '../../application/providers/board_provider.dart';
import 'tile_widget.dart';

/// Renders the whole board.
///
/// Uses its own inner [LayoutBuilder] (separate from the app-level one
/// in main.dart, which only picks the ScreenUtil design size) to fit a
/// square grid of tiles into whatever space its parent gives it —
/// phone, tablet, split-screen, or desktop window, all handled the
/// same way.
///
/// Phase 3/4: each tile is wired to [GameNotifier.onTileTapped], and
/// `Positioned` was upgraded to `AnimatedPositioned` (keyed by
/// `tile.id`) so swaps, invalid-move bounce-backs, and post-cascade
/// falls all animate to their new grid position instead of popping.
/// Null cells (briefly empty mid-cascade) are simply skipped.
class GridWidget extends ConsumerWidget {
  const GridWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final board = gameState.board;
    final spacing = BoardConfig.tileSpacing.w;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHSpacing = spacing * (board.cols - 1);
        final totalVSpacing = spacing * (board.rows - 1);

        final maxTileWidth =
            (constraints.maxWidth - totalHSpacing) / board.cols;
        final maxTileHeight =
            (constraints.maxHeight - totalVSpacing) / board.rows;

        final tileSize =
            maxTileWidth < maxTileHeight ? maxTileWidth : maxTileHeight;

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
                    if (tile != null)
                      AnimatedPositioned(
                        key: ValueKey(tile.id),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        left: tile.col * (tileSize + spacing),
                        top: tile.row * (tileSize + spacing),
                        width: tileSize,
                        height: tileSize,
                        child: TileWidget(
                          tile: tile,
                          size: tileSize,
                          isSelected: gameState.selectedTileId == tile.id,
                          onTap: () => ref
                              .read(gameProvider.notifier)
                              .onTileTapped(tile),
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
