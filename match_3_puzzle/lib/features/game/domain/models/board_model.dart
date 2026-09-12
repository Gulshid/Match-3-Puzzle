import 'dart:math';

import '../enums/tile_type.dart';
import '../models/tile_model.dart';
import 'level_config.dart';

/// The game board: an immutable rows x cols grid of tiles.
///
/// Phase 9 additions:
/// - [activateSpecialAt]: fires a special tile's area effect, returning
///   the set of positions it cleared so the notifier can score them.
/// - [spawnSpecialAt]: places a newly created special tile in a cell.
/// - Obstacle-awareness: ice and crate cells participate in match
///   adjacency checks.
///
/// Phase 10 additions:
/// - [obstacles]: a fixed map of (col,row) → ObstacleType loaded from the
///   level config. Obstacles are separate from the tile grid — a tile can
///   sit on top of an ice cell.
/// - [iceHits]: tracks how many hits an ice cell has taken (requires 1 hit
///   to break; crates require adjacent matches).
class BoardModel {
  final int rows;
  final int cols;
  final List<List<TileModel?>> grid;

  // Phase 10: obstacle state
  final Map<Point<int>, ObstacleType> obstacles;
  final Map<Point<int>, int> iceHits; // Point(col,row) → hit count

  const BoardModel({
    required this.rows,
    required this.cols,
    required this.grid,
    this.obstacles = const {},
    this.iceHits = const {},
  });

  TileModel? tileAt(int row, int col) => grid[row][col];

  bool hasObstacle(int row, int col) =>
      obstacles.containsKey(Point(col, row));

  ObstacleType? obstacleAt(int row, int col) =>
      obstacles[Point(col, row)];

  bool isIceBroken(int row, int col) =>
      (iceHits[Point(col, row)] ?? 0) >= 1;

  // ─── Tile mutations ───────────────────────────────────────────────

  BoardModel withTile(int row, int col, TileModel? tile) {
    final newGrid = _copyGrid();
    newGrid[row][col] = tile;
    return _copyWithGrid(newGrid);
  }

  BoardModel swapTiles(int r1, int c1, int r2, int c2) {
    final newGrid = _copyGrid();
    final a = newGrid[r1][c1];
    final b = newGrid[r2][c2];

    // Can't swap into a crate cell.
    if (obstacles[Point(c1, r1)] == ObstacleType.crate ||
        obstacles[Point(c2, r2)] == ObstacleType.crate) {
      return this;
    }

    newGrid[r1][c1] = b?.copyWith(row: r1, col: c1);
    newGrid[r2][c2] = a?.copyWith(row: r2, col: c2);

    return _copyWithGrid(newGrid);
  }

  BoardModel markMatched(Set<Point<int>> positions) {
    final newGrid = _copyGrid();
    final newIceHits = Map<Point<int>, int>.from(iceHits);

    for (final p in positions) {
      final tile = newGrid[p.y][p.x];
      if (tile != null) {
        newGrid[p.y][p.x] = tile.copyWith(isMatched: true);
      }

      // Break adjacent ice cells.
      for (final n in _neighbours(p.y, p.x)) {
        final key = Point(n.x, n.y); // Point(col, row)
        if (obstacles[key] == ObstacleType.ice) {
          newIceHits[key] = (newIceHits[key] ?? 0) + 1;
        }
      }

      // Crates adjacent to a match are destroyed.
      // (In this implementation we remove the obstacle from the map.)
      for (final n in _neighbours(p.y, p.x)) {
        final key = Point(n.x, n.y);
        if (obstacles[key] == ObstacleType.crate) {
          // We'll handle crate removal in a separate step via
          // [clearCratesAdjacentTo] so callers can animate it.
        }
      }
    }

    return BoardModel(
      rows: rows,
      cols: cols,
      grid: newGrid,
      obstacles: obstacles,
      iceHits: newIceHits,
    );
  }

  /// Removes (sets to null) every tile currently flagged as matched.
  /// Also removes ice obstacles that have been hit enough.
  BoardModel clearMatched() {
    final newGrid = _copyGrid();
    final newObstacles = Map<Point<int>, ObstacleType>.from(obstacles);
    final newIceHits = Map<Point<int>, int>.from(iceHits);

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (newGrid[row][col]?.isMatched == true) {
          newGrid[row][col] = null;
        }
        // Remove broken ice.
        final key = Point(col, row);
        if (newObstacles[key] == ObstacleType.ice &&
            (newIceHits[key] ?? 0) >= 1) {
          newObstacles.remove(key);
          newIceHits.remove(key);
        }
      }
    }

    return BoardModel(
      rows: rows,
      cols: cols,
      grid: newGrid,
      obstacles: newObstacles,
      iceHits: newIceHits,
    );
  }

  /// Removes crates adjacent to any of the given [matchedPositions].
  BoardModel clearAdjacentCrates(Set<Point<int>> matchedPositions) {
    final newObstacles = Map<Point<int>, ObstacleType>.from(obstacles);

    for (final p in matchedPositions) {
      for (final n in _neighbours(p.y, p.x)) {
        final key = Point(n.x, n.y);
        if (newObstacles[key] == ObstacleType.crate) {
          newObstacles.remove(key);
        }
      }
    }

    return BoardModel(
      rows: rows,
      cols: cols,
      grid: grid,
      obstacles: newObstacles,
      iceHits: iceHits,
    );
  }

  /// Phase 9: Fires the area effect of the special tile at [row],[col].
  ///
  /// Returns the set of extra positions cleared by the effect (in addition
  /// to the special tile itself, which is already in the normal match set).
  Set<Point<int>> activateSpecialAt(
    int row,
    int col,
    BoardModel board, {
    TileType? swappedWithType,
  }) {
    final tile = tileAt(row, col);
    if (tile == null || !tile.isSpecial) return {};

    final extra = <Point<int>>{};

    switch (tile.specialType!) {
      case SpecialTileType.striped:
        if (tile.stripeDirection == StripeDirection.horizontal) {
          for (var c = 0; c < cols; c++) {
            extra.add(Point(c, row));
          }
        } else {
          for (var r = 0; r < rows; r++) {
            extra.add(Point(col, r));
          }
        }
        break;

      case SpecialTileType.wrapped:
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            final r = row + dr;
            final c = col + dc;
            if (r >= 0 && r < rows && c >= 0 && c < cols) {
              extra.add(Point(c, r));
            }
          }
        }
        break;

      case SpecialTileType.colorBomb:
        final targetType = swappedWithType ?? _randomType();
        for (var r = 0; r < rows; r++) {
          for (var c = 0; c < cols; c++) {
            if (tileAt(r, c)?.type == targetType) {
              extra.add(Point(c, r));
            }
          }
        }
        break;
    }

    return extra;
  }

  /// Phase 9: Replaces the tile at [row],[col] with a new special tile
  /// of [specialType], keeping the original tile's [TileType].
  BoardModel spawnSpecialAt(
    int row,
    int col,
    SpecialTileType specialType, {
    StripeDirection? stripeDirection,
    TileType? forceType,
  }) {
    final existing = tileAt(row, col);
    final type = forceType ?? existing?.type ?? TileType.values.first;
    final newGrid = _copyGrid();

    newGrid[row][col] = TileModel(
      id: 'special_${DateTime.now().microsecondsSinceEpoch}_${row}_$col',
      type: type,
      row: row,
      col: col,
      specialType: specialType,
      stripeDirection: stripeDirection,
    );

    return _copyWithGrid(newGrid);
  }

  // ─── Gravity & refill ─────────────────────────────────────────────

  BoardModel applyGravity() {
    final newGrid = _copyGrid();

    for (var col = 0; col < cols; col++) {
      final surviving = <TileModel>[];
      for (var row = 0; row < rows; row++) {
        final tile = newGrid[row][col];
        // Skip crate cells — gravity doesn't move tiles through them.
        if (tile != null &&
            obstacles[Point(col, row)] != ObstacleType.crate) {
          surviving.add(tile);
        }
      }

      final emptyCount = rows - surviving.length;

      for (var row = 0; row < rows; row++) {
        if (obstacles[Point(col, row)] == ObstacleType.crate) continue;

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

  BoardModel refill(Random rng) {
    final newGrid = _copyGrid();
    var spawnCount = 0;
    final types = TileType.values;
    final stamp = DateTime.now().microsecondsSinceEpoch;

    for (var col = 0; col < cols; col++) {
      for (var row = 0; row < rows; row++) {
        if (newGrid[row][col] == null &&
            obstacles[Point(col, row)] != ObstacleType.crate) {
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

  // ─── Factory ──────────────────────────────────────────────────────

  factory BoardModel.generateRandom({
    required int rows,
    required int cols,
    Random? random,
    Map<Point<int>, ObstacleType> obstacles = const {},
  }) {
    final rng = random ?? Random();
    final types = TileType.values;
    var idCounter = 0;

    final grid = List<List<TileModel?>>.generate(
      rows,
      (row) => List<TileModel?>.generate(
        cols,
        (col) => obstacles[Point(col, row)] == ObstacleType.crate
            ? null // crate cells start empty
            : TileModel(
                id: 'tile_${idCounter++}',
                type: types[rng.nextInt(types.length)],
                row: row,
                col: col,
              ),
      ),
    );

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (obstacles[Point(col, row)] == ObstacleType.crate) continue;
        var attempts = 0;
        while (_completesMatch(grid, row, col) && attempts < 20) {
          grid[row][col] = grid[row][col]!.copyWith(
            type: types[rng.nextInt(types.length)],
          );
          attempts++;
        }
      }
    }

    return BoardModel(
      rows: rows,
      cols: cols,
      grid: grid,
      obstacles: obstacles,
    );
  }

  static bool _completesMatch(List<List<TileModel?>> grid, int row, int col) {
    final type = grid[row][col]?.type;
    if (type == null) return false;

    if (col >= 2 &&
        grid[row][col - 1]?.type == type &&
        grid[row][col - 2]?.type == type) return true;

    if (row >= 2 &&
        grid[row - 1][col]?.type == type &&
        grid[row - 2][col]?.type == type) return true;

    return false;
  }

  // ─── Private helpers ──────────────────────────────────────────────

  List<List<TileModel?>> _copyGrid() => [
        for (final r in grid) [...r],
      ];

  BoardModel _copyWithGrid(List<List<TileModel?>> newGrid) => BoardModel(
        rows: rows,
        cols: cols,
        grid: newGrid,
        obstacles: obstacles,
        iceHits: iceHits,
      );

  TileType _randomType() =>
      TileType.values[DateTime.now().microsecond % TileType.values.length];

  List<Point<int>> _neighbours(int row, int col) {
    final result = <Point<int>>[];
    if (row > 0) result.add(Point(col, row - 1));
    if (row < rows - 1) result.add(Point(col, row + 1));
    if (col > 0) result.add(Point(col - 1, row));
    if (col < cols - 1) result.add(Point(col + 1, row));
    return result;
  }
}
