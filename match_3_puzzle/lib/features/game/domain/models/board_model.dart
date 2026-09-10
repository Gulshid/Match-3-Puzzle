import 'dart:math';

import '../enums/tile_type.dart';
import 'tile_model.dart';

/// The game board: an immutable rows x cols grid of tiles.
///
/// Cells are nullable ([TileModel?]) as of Phase 4 — a `null` cell
/// represents a temporarily empty space between "matched tiles cleared"
/// and "gravity + refill" finishing. By the time the UI reads state
/// again after a cascade settles, every cell is non-null again.
class BoardModel {
  final int rows;
  final int cols;
  final List<List<TileModel?>> grid;

  const BoardModel({
    required this.rows,
    required this.cols,
    required this.grid,
  });

  TileModel? tileAt(int row, int col) => grid[row][col];

  /// Returns a new board with a single cell replaced.
  BoardModel withTile(int row, int col, TileModel? tile) {
    final newGrid = _copyGrid();
    newGrid[row][col] = tile;
    return _copyWithGrid(newGrid);
  }

  /// Returns a new board with the tiles at (r1,c1) and (r2,c2) swapped.
  /// Each tile's row/col fields are updated to match its new cell, so
  /// its `id` (and therefore its widget key) animates smoothly between
  /// the two positions instead of popping.
  BoardModel swapTiles(int r1, int c1, int r2, int c2) {
    final newGrid = _copyGrid();
    final a = newGrid[r1][c1];
    final b = newGrid[r2][c2];

    newGrid[r1][c1] = b?.copyWith(row: r1, col: c1);
    newGrid[r2][c2] = a?.copyWith(row: r2, col: c2);

    return _copyWithGrid(newGrid);
  }

  /// Flags every tile at the given positions as matched. The tile stays
  /// on the board (still rendered) so the UI can play a brief "matched"
  /// state before [clearMatched] actually removes it.
  BoardModel markMatched(Set<Point<int>> positions) {
    final newGrid = _copyGrid();
    for (final p in positions) {
      final tile = newGrid[p.y][p.x];
      if (tile != null) {
        newGrid[p.y][p.x] = tile.copyWith(isMatched: true);
      }
    }
    return _copyWithGrid(newGrid);
  }

  /// Removes (sets to null) every tile currently flagged as matched.
  BoardModel clearMatched() {
    final newGrid = _copyGrid();
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (newGrid[row][col]?.isMatched == true) {
          newGrid[row][col] = null;
        }
      }
    }
    return _copyWithGrid(newGrid);
  }

  /// Applies gravity: within each column, non-null tiles drop down to
  /// fill empty cells below them, preserving relative order. Leaves
  /// nulls at the top of any column that lost tiles.
  BoardModel applyGravity() {
    final newGrid = _copyGrid();

    for (var col = 0; col < cols; col++) {
      final surviving = <TileModel>[];
      for (var row = 0; row < rows; row++) {
        final tile = newGrid[row][col];
        if (tile != null) surviving.add(tile);
      }

      final emptyCount = rows - surviving.length;

      for (var row = 0; row < rows; row++) {
        if (row < emptyCount) {
          newGrid[row][col] = null;
        } else {
          final tile = surviving[row - emptyCount];
          newGrid[row][col] = tile.copyWith(row: row, col: col);
        }
      }
    }

    return _copyWithGrid(newGrid);
  }

  /// Fills any remaining null cells (after [applyGravity] these sit at
  /// the top of their columns) with freshly spawned random tiles.
  BoardModel refill(Random rng) {
    final newGrid = _copyGrid();
    var spawnCount = 0;
    final types = TileType.values;
    final stamp = DateTime.now().microsecondsSinceEpoch;

    for (var col = 0; col < cols; col++) {
      for (var row = 0; row < rows; row++) {
        if (newGrid[row][col] == null) {
          newGrid[row][col] = TileModel(
            id: 'tile_${stamp}_${spawnCount++}',
            type: types[rng.nextInt(types.length)],
            row: row,
            col: col,
          );
        }
      }
    }

    return _copyWithGrid(newGrid);
  }

  bool get hasEmptyCells =>
      grid.any((row) => row.any((tile) => tile == null));

  List<List<TileModel?>> _copyGrid() => [
        for (final r in grid) [...r],
      ];

  BoardModel _copyWithGrid(List<List<TileModel?>> newGrid) =>
      BoardModel(rows: rows, cols: cols, grid: newGrid);

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

    final grid = List<List<TileModel?>>.generate(
      rows,
      (row) => List<TileModel?>.generate(
        cols,
        (col) => TileModel(
          id: 'tile_${idCounter++}',
          type: types[rng.nextInt(types.length)],
          row: row,
          col: col,
        ),
      ),
    );

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        var attempts = 0;
        while (_completesMatch(grid, row, col) && attempts < 20) {
          grid[row][col] = grid[row][col]!.copyWith(
            type: types[rng.nextInt(types.length)],
          );
          attempts++;
        }
      }
    }

    return BoardModel(rows: rows, cols: cols, grid: grid);
  }

  static bool _completesMatch(List<List<TileModel?>> grid, int row, int col) {
    final type = grid[row][col]!.type;

    if (col >= 2 &&
        grid[row][col - 1]?.type == type &&
        grid[row][col - 2]?.type == type) {
      return true;
    }

    if (row >= 2 &&
        grid[row - 1][col]?.type == type &&
        grid[row - 2][col]?.type == type) {
      return true;
    }

    return false;
  }
}
