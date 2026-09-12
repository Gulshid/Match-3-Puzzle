import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/design_constants.dart';
import '../../application/providers/board_provider.dart';
import '../../domain/models/level_config.dart';
import 'tile_widget.dart';

/// Renders the full game board including normal tiles, special tiles,
/// ice overlays, and crate blockers.
///
/// Phase 9: passes [isActivating] to [TileWidget] so the one tile that
/// is about to fire its special effect gets a white flash.
///
/// Phase 10: renders [CrateTileWidget] in cells where the board has a
/// crate obstacle, and [TileWidget] with [obstacleType] set for ice cells.
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
                // ── Background cell slots ──────────────────────────
                for (var row = 0; row < board.rows; row++)
                  for (var col = 0; col < board.cols; col++)
                    Positioned(
                      left: col * (tileSize + spacing),
                      top: row * (tileSize + spacing),
                      width: tileSize,
                      height: tileSize,
                      child: _CellBackground(size: tileSize),
                    ),

                // ── Phase 10: Crate obstacles ──────────────────────
                for (final entry in board.obstacles.entries)
                  if (entry.value == ObstacleType.crate)
                    Positioned(
                      left: entry.key.x * (tileSize + spacing),
                      top: entry.key.y * (tileSize + spacing),
                      width: tileSize,
                      height: tileSize,
                      child: CrateTileWidget(size: tileSize),
                    ),

                // ── Tiles ──────────────────────────────────────────
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
                          // Phase 9: flash when this tile is activating.
                          isActivating:
                              gameState.activatingSpecialId == tile.id,
                          // Phase 10: pass ice overlay info.
                          obstacleType: board.obstacleAt(tile.row, tile.col),
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

/// Subtle dark rounded background drawn behind every cell — gives the
/// board a "slot" feel so empty spaces during cascades are visible.
class _CellBackground extends StatelessWidget {
  const _CellBackground({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(BoardConfig.tileRadius.r),
      ),
    );
  }
}
