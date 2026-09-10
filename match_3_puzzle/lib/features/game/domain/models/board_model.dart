import 'dart:math';

import 'package:match3_puzzle/features/game/domain/enums/tile_type.dart';
import 'package:match3_puzzle/features/game/domain/models/tile_model.dart';

/// The game board: an immutable rows x cols grid of tiles.
///
/// Stored as `grid[row][col]`. Immutable by design — the Riverpod
/// StateNotifier in Phase 3/4 will produce new BoardModel instances on
/// every change rather than mutating this one, which keeps swap/match/
/// cascade logic easy to reason about (and easy to animate later).
class BoardModel {
  final int rows;
  final int cols;
  final List<List<TileModel>> grid;

  const BoardModel({
    required this.rows,
    required this.cols,
    required this.grid,
  });

  TileModel tileAt(int row, int col) => grid[row][col];

  /// Returns a new board with a single tile replaced.
  BoardModel withTile(TileModel tile) {
    final newGrid = [
      for (final r in grid) [...r],
    ];
    newGrid[tile.row][tile.col] = tile;
    return BoardModel(rows: rows, cols: cols, grid: newGrid);
  }

  /// Generates a random board with no pre-existing 3-in-a-row matches,
  /// so the player never starts a level with a "free" match already on
  /// the board.
  factory BoardModel.generateRandom({
    required int rows,
    required int cols,
    Random? random,
  }) {
    final rng = random ?? Random();
    final types = TileType.values;
    var idCounter = 0;

    final grid = List.generate(
      rows,
      (row) => List.generate(
        cols,
        (col) => TileModel(
          id: 'tile_${idCounter++}',
          type: types[rng.nextInt(types.length)],
          row: row,
          col: col,
        ),
      ),
    );

    // Second pass: regenerate any tile whose placement completes a match,
    // now that full rows exist to check against. Doing it in a second
    // pass keeps the generation logic simple and easy to follow.
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        var attempts = 0;
        while (_completesMatch(grid, row, col) && attempts < 20) {
          grid[row][col] = grid[row][col].copyWith(
            type: types[rng.nextInt(types.length)],
          );
          attempts++;
        }
      }
    }

    return BoardModel(rows: rows, cols: cols, grid: grid);
  }

  static bool _completesMatch(List<List<TileModel>> grid, int row, int col) {
    final type = grid[row][col].type;

    // Horizontal: this tile plus the two immediately to its left.
    if (col >= 2 &&
        grid[row][col - 1].type == type &&
        grid[row][col - 2].type == type) {
      return true;
    }

    // Vertical: this tile plus the two immediately above it.
    if (row >= 2 &&
        grid[row - 1][col].type == type &&
        grid[row - 2][col].type == type) {
      return true;
    }

    return false;
  }
}
