import 'dart:math';

import '../enums/tile_type.dart';
import '../models/board_model.dart';

/// Describes a match group: which cells are matched, how many tiles were
/// in the run that formed it, and what special tile (if any) should be
/// spawned at the pivot position.
class MatchResult {
  /// All grid positions (col, row) included in this match.
  final Set<Point<int>> positions;

  /// The grid cell where the newly-created special tile should be placed.
  /// Null when no special tile is created (normal 3-match).
  final Point<int>? specialSpawnAt;

  /// What kind of special tile to spawn. Null for a plain 3-match.
  final SpecialTileType? specialType;

  /// For striped tiles — which direction.
  final StripeDirection? stripeDirection;

  const MatchResult({
    required this.positions,
    this.specialSpawnAt,
    this.specialType,
    this.stripeDirection,
  });
}

/// Pure, stateless match-finding logic — now Phase-9-aware.
///
/// Detects:
/// - 3-in-a-row/col → plain match (no special spawn)
/// - 4-in-a-row/col → spawns a striped tile at the swapped position
/// - L/T shape (two intersecting runs) → spawns a wrapped tile
/// - 5-in-a-row/col → spawns a color bomb
class MatchDetector {
  MatchDetector._();

  /// Returns every grid position that is part of a horizontal or
  /// vertical run of 3+ same-type tiles, merged into [MatchResult]s.
  static List<MatchResult> findMatchResults(BoardModel board) {
    final hRuns = _scanRuns(board, horizontal: true);
    final vRuns = _scanRuns(board, horizontal: false);

    // Combine overlapping runs (L/T shapes) into wrapped specials.
    final results = <MatchResult>[];
    final usedH = <_Run>{};
    final usedV = <_Run>{};

    for (final h in hRuns) {
      for (final v in vRuns) {
        final intersection = h.positions.intersection(v.positions);
        if (intersection.isNotEmpty) {
          // Two runs share at least one cell → L/T or + shape.
          final combined = h.positions.union(v.positions);
          final pivot = intersection.first;
          final specialType = (h.length >= 5 || v.length >= 5)
              ? SpecialTileType.colorBomb
              : (h.length >= 4 || v.length >= 4)
                  ? SpecialTileType.striped
                  : SpecialTileType.wrapped;
          results.add(MatchResult(
            positions: combined,
            specialSpawnAt: pivot,
            specialType: specialType,
            stripeDirection: specialType == SpecialTileType.striped
                ? (h.length >= 4
                    ? StripeDirection.horizontal
                    : StripeDirection.vertical)
                : null,
          ));
          usedH.add(h);
          usedV.add(v);
        }
      }
    }

    // Remaining standalone horizontal runs.
    for (final h in hRuns) {
      if (usedH.contains(h)) continue;
      results.add(_runToResult(h, horizontal: true));
    }

    // Remaining standalone vertical runs.
    for (final v in vRuns) {
      if (usedV.contains(v)) continue;
      results.add(_runToResult(v, horizontal: false));
    }

    return results;
  }

  /// Flat set of all matched positions — used by the cascade loop for
  /// quick "is there anything to clear?" checks.
  static Set<Point<int>> findMatches(BoardModel board) {
    final all = <Point<int>>{};
    for (final r in findMatchResults(board)) {
      all.addAll(r.positions);
    }
    return all;
  }

  /// Whether swapping (r1,c1) with (r2,c2) would produce at least one
  /// match — used for the "no possible moves" detector.
  static bool wouldCreateMatch(
    BoardModel board,
    int r1,
    int c1,
    int r2,
    int c2,
  ) {
    final swapped = board.swapTiles(r1, c1, r2, c2);
    return findMatches(swapped).isNotEmpty;
  }

  // ─── Private helpers ────────────────────────────────────────────────

  static List<_Run> _scanRuns(BoardModel board, {required bool horizontal}) {
    final runs = <_Run>[];
    final outer = horizontal ? board.rows : board.cols;
    final inner = horizontal ? board.cols : board.rows;

    for (var o = 0; o < outer; o++) {
      var runStart = 0;
      for (var i = 1; i <= inner; i++) {
        TileType? currentType;
        if (i < inner) {
          final tile =
              horizontal ? board.tileAt(o, i) : board.tileAt(i, o);
          currentType = tile?.type;
        }
        final startTile = horizontal
            ? board.tileAt(o, runStart)
            : board.tileAt(runStart, o);
        final runType = startTile?.type;

        if (currentType == null || currentType != runType) {
          final runLength = i - runStart;
          if (runLength >= 3 && runType != null) {
            final positions = <Point<int>>{};
            for (var k = runStart; k < i; k++) {
              positions.add(
                horizontal ? Point(k, o) : Point(o, k),
              );
            }
            runs.add(_Run(positions: positions, length: runLength));
          }
          runStart = i;
        }
      }
    }
    return runs;
  }

  static MatchResult _runToResult(_Run run, {required bool horizontal}) {
    SpecialTileType? special;
    StripeDirection? dir;

    if (run.length >= 5) {
      special = SpecialTileType.colorBomb;
    } else if (run.length == 4) {
      special = SpecialTileType.striped;
      dir = horizontal ? StripeDirection.horizontal : StripeDirection.vertical;
    }

    // Spawn at the middle of the run.
    final pivot = run.positions.elementAt(run.length ~/ 2);

    return MatchResult(
      positions: run.positions,
      specialSpawnAt: special != null ? pivot : null,
      specialType: special,
      stripeDirection: dir,
    );
  }
}

class _Run {
  final Set<Point<int>> positions;
  final int length;

  const _Run({required this.positions, required this.length});
}
