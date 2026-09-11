import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/design_constants.dart';
import '../../application/providers/board_provider.dart';
import '../../domain/models/level_config.dart';
import 'tile_widget.dart';

/// Renders the whole board for [level]'s game state.
///
/// Uses its own inner [LayoutBuilder] (separate from the app-level one
/// in main.dart, which only picks the ScreenUtil design size) to fit a
/// square grid of tiles into whatever space its parent gives it —
/// phone, tablet, split-screen, or desktop window, all handled the
/// same way.
///
/// Phase 3/4: each tile is wired to [GameNotifier.onTileTapped], and
/// `Positioned` was upgraded to `AnimatedPositioned` (keyed by
/// `tile.id`) so swaps, bounce-backs, and post-cascade falls all
/// animate to their new grid position instead of popping. Null cells
/// (briefly empty mid-cascade) are simply skipped.
///
/// Phase 6: the curve switches to a bouncier `easeOutBack` for the one
/// transition where an invalid swap reverts (`isInvalidSwapFeedback`).
/// `Clip.none` lets new tiles (spawned above the board — see
/// `_withSpawnEntryOffsets` in the notifier) render before they've
/// animated into view.
///
/// Phase 7: takes [level] so it can read the right `gameProvider(level)`
/// instance now that the provider is a family keyed by level.
class GridWidget extends ConsumerWidget {
  const GridWidget({super.key, required this.level});

  final LevelConfig level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider(level));
    final board = gameState.board;
    final spacing = BoardConfig.tileSpacing.w;

    final moveCurve = gameState.isInvalidSwapFeedback
        ? Curves.easeOutBack
        : Curves.easeInOutCubic;

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
              clipBehavior: Clip.none,
              children: [
                for (final row in board.grid)
                  for (final tile in row)
                    if (tile != null)
                      AnimatedPositioned(
                        key: ValueKey(tile.id),
                        duration: const Duration(milliseconds: 220),
                        curve: moveCurve,
                        left: tile.col * (tileSize + spacing),
                        top: tile.row * (tileSize + spacing),
                        width: tileSize,
                        height: tileSize,
                        child: TileWidget(
                          tile: tile,
                          size: tileSize,
                          isSelected: gameState.selectedTileId == tile.id,
                          onTap: () => ref
                              .read(gameProvider(level).notifier)
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
