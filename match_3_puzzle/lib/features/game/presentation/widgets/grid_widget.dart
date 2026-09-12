import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/design_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/providers/board_provider.dart';
import '../../domain/models/level_config.dart';
import 'tile_widget.dart';

/// Renders the full game board inside a glossy 3D "tabletop" frame:
/// a beveled outer panel with perspective tilt gives the whole board a
/// sense of depth, while individual cells sit in inset glass slots.
class GridWidget extends ConsumerWidget {
  const GridWidget({super.key, required this.level});

  final LevelConfig level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider(level));
    final board = gameState.board;
    final spacing = BoardConfig.tileSpacing.w;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final moveCurve = gameState.isInvalidSwapFeedback
        ? Curves.easeOutBack
        : Curves.easeInOutCubic;

    return LayoutBuilder(
      builder: (context, constraints) {
        final framePadding = 12.r;
        final availableWidth = constraints.maxWidth - framePadding * 2;
        final availableHeight = constraints.maxHeight - framePadding * 2;

        final totalHSpacing = spacing * (board.cols - 1);
        final totalVSpacing = spacing * (board.rows - 1);

        final maxTileWidth = (availableWidth - totalHSpacing) / board.cols;
        final maxTileHeight = (availableHeight - totalVSpacing) / board.rows;

        final tileSize =
            maxTileWidth < maxTileHeight ? maxTileWidth : maxTileHeight;

        final boardWidth = board.cols * tileSize + totalHSpacing;
        final boardHeight = board.rows * tileSize + totalVSpacing;

        return Center(
          child: Transform(
            alignment: Alignment.center,
            // Very subtle "tabletop" perspective — the board reads as
            // a physical panel viewed slightly from above, without
            // distorting gameplay legibility.
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0009)
              ..rotateX(0.045),
            child: Container(
              padding: EdgeInsets.all(framePadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? AppColors.boardFrameDark
                      : AppColors.boardFrameLight,
                ),
                borderRadius: BorderRadius.circular(BoardConfig.tileRadius.r + 10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.06),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Background cell slots ──────────────────────
                    for (var row = 0; row < board.rows; row++)
                      for (var col = 0; col < board.cols; col++)
                        Positioned(
                          left: col * (tileSize + spacing),
                          top: row * (tileSize + spacing),
                          width: tileSize,
                          height: tileSize,
                          child: _CellBackground(size: tileSize),
                        ),

                    // ── Crate obstacles ──────────────────────────────
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
                              isActivating:
                                  gameState.activatingSpecialId == tile.id,
                              obstacleType:
                                  board.obstacleAt(tile.row, tile.col),
                              onTap: () => ref
                                  .read(gameProvider(level).notifier)
                                  .onTileTapped(tile),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Inset "glass slot" drawn behind every cell — a subtle radial shading
/// gives each socket real depth so tiles look like they're sitting
/// inside the board rather than floating flat on top of it.
class _CellBackground extends StatelessWidget {
  const _CellBackground({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BoardConfig.tileRadius.r),
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.1,
          colors: [
            Colors.black.withOpacity(0.06),
            Colors.black.withOpacity(0.22),
          ],
        ),
        border: Border.all(color: Colors.black.withOpacity(0.18), width: 1),
      ),
    );
  }
}
