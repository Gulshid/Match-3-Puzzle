import 'dart:math';

import '../models/board_model.dart';

/// Pure, stateless match-finding logic.
///
/// Kept independent of [GameNotifier] so it's trivial to unit test on
/// its own (Phase 12) and easy to reuse for "would this swap create a
/// match" checks without mutating any state.
///
/// Positions are `Point<int>(col, row)` — x = column, y = row.
class MatchDetector {
  MatchDetector._();

  /// Returns every grid position that is part of a horizontal or
  /// vertical run of 3+ same-type tiles.
  static Set<Point<int>> findMatches(BoardModel board) {
    final matched = <Point<int>>{};

    // Horizontal runs — scan each row left to right.
    for (var row = 0; row < board.rows; row++) {
      var runStart = 0;
      for (var col = 1; col <= board.cols; col++) {
        final currentType =
            col < board.cols ? board.tileAt(row, col)?.type : null;
        final runType = board.tileAt(row, runStart)?.type;

        if (currentType == null || currentType != runType) {
          final runLength = col - runStart;
          if (runLength >= 3 && runType != null) {
            for (var c = runStart; c < col; c++) {
              matched.add(Point(c, row));
            }
          }
          runStart = col;
        }
      }
    }

    // Vertical runs — scan each column top to bottom.
    for (var col = 0; col < board.cols; col++) {
      var runStart = 0;
      for (var row = 1; row <= board.rows; row++) {
        final currentType =
            row < board.rows ? board.tileAt(row, col)?.type : null;
        final runType = board.tileAt(runStart, col)?.type;

        if (currentType == null || currentType != runType) {
          final runLength = row - runStart;
          if (runLength >= 3 && runType != null) {
            for (var r = runStart; r < row; r++) {
              matched.add(Point(col, r));
            }
          }
          runStart = row;
        }
      }
    }

    return matched;
  }

  /// Whether swapping (r1,c1) with (r2,c2) would produce at least one
  /// match. Useful later (Phase 5) for "no possible moves" detection.
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
}
