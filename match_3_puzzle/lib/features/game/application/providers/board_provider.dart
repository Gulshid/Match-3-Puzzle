import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/design_constants.dart';
import '../../domain/models/board_model.dart';
import '../../domain/models/level_config.dart';
import '../../domain/models/tile_model.dart';
import '../../domain/services/match_detector.dart';

/// Everything the UI needs to render and interact with the board.
class GameState {
  final BoardModel board;
  final LevelConfig level;
  final String? selectedTileId;
  final bool isProcessing;
  final int comboCount;

  /// True only for the single state update where a swap is being
  /// reverted (no match). GridWidget uses this to pick a bouncier curve
  /// for that one transition — see Phase 6 notes there.
  final bool isInvalidSwapFeedback;

  /// Bumped (never reset) whenever a cascade combo reaches 3+ passes,
  /// so a listener (ShakeWidget) can replay a shake purely by diffing
  /// this value — no separate "consume the event" bookkeeping needed.
  final int shakeTrigger;

  final int score;
  final int movesRemaining;
  final GameStatus status;

  const GameState({
    required this.board,
    required this.level,
    this.selectedTileId,
    this.isProcessing = false,
    this.comboCount = 0,
    this.isInvalidSwapFeedback = false,
    this.shakeTrigger = 0,
    this.score = 0,
    required this.movesRemaining,
    this.status = GameStatus.playing,
  });

  GameState copyWith({
    BoardModel? board,
    LevelConfig? level,
    String? selectedTileId,
    bool clearSelection = false,
    bool? isProcessing,
    int? comboCount,
    bool? isInvalidSwapFeedback,
    int? shakeTrigger,
    int? score,
    int? movesRemaining,
    GameStatus? status,
  }) {
    return GameState(
      board: board ?? this.board,
      level: level ?? this.level,
      selectedTileId:
          clearSelection ? null : (selectedTileId ?? this.selectedTileId),
      isProcessing: isProcessing ?? this.isProcessing,
      comboCount: comboCount ?? this.comboCount,
      isInvalidSwapFeedback:
          isInvalidSwapFeedback ?? this.isInvalidSwapFeedback,
      shakeTrigger: shakeTrigger ?? this.shakeTrigger,
      score: score ?? this.score,
      movesRemaining: movesRemaining ?? this.movesRemaining,
      status: status ?? this.status,
    );
  }
}

/// Owns the board and all swap/match/cascade/scoring logic.
///
/// Phase 3: tap-to-select, adjacency-restricted swapping, match detection.
/// Phase 4: clear -> gravity -> refill -> re-check cascade loop + combo count.
/// Phase 5: scoring, move limit, win/lose, and a "no possible moves"
///          auto-reshuffle.
/// Phase 6: spawn-from-above entry animation for new tiles, an
///          invalid-swap bounce curve flag, and a big-combo shake trigger.
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier()
      : super(
          GameState(
            board: BoardModel.generateRandom(
              rows: BoardConfig.rows,
              cols: BoardConfig.cols,
            ),
            level: LevelConfig.defaultLevel,
            movesRemaining: LevelConfig.defaultLevel.moveLimit,
          ),
        );

  final Random _random = Random();

  static const _swapDuration = Duration(milliseconds: 220);
  static const _matchPauseDuration = Duration(milliseconds: 200);
  static const _cascadeStepDuration = Duration(milliseconds: 260);

  /// One frame's worth of delay so the "entry" (spawn-above) board
  /// actually paints before we jump to the settled positions — without
  /// this, Flutter can coalesce both state updates into a single frame
  /// and the drop-in animation never has a starting point to animate from.
  static const _spawnEntryFrameDelay = Duration(milliseconds: 32);

  static const int _bigComboThreshold = 3;
  static const int _pointsPerTile = 10;

  void newGame({LevelConfig? level}) {
    final newLevel = level ?? state.level;
    state = GameState(
      board: BoardModel.generateRandom(
        rows: BoardConfig.rows,
        cols: BoardConfig.cols,
        random: _random,
      ),
      level: newLevel,
      movesRemaining: newLevel.moveLimit,
    );
  }

  Future<void> onTileTapped(TileModel tile) async {
    if (state.isProcessing || state.status != GameStatus.playing) return;

    final selectedId = state.selectedTileId;
    if (selectedId == null) {
      state = state.copyWith(selectedTileId: tile.id);
      return;
    }

    if (selectedId == tile.id) {
      state = state.copyWith(clearSelection: true);
      return;
    }

    final selectedTile = _findTileById(selectedId);
    if (selectedTile == null || !_isAdjacent(selectedTile, tile)) {
      state = state.copyWith(selectedTileId: tile.id);
      return;
    }

    await _trySwap(selectedTile, tile);
  }

  TileModel? _findTileById(String id) {
    for (final row in state.board.grid) {
      for (final t in row) {
        if (t?.id == id) return t;
      }
    }
    return null;
  }

  bool _isAdjacent(TileModel a, TileModel b) {
    final dRow = (a.row - b.row).abs();
    final dCol = (a.col - b.col).abs();
    return (dRow == 1 && dCol == 0) || (dRow == 0 && dCol == 1);
  }

  Future<void> _trySwap(TileModel a, TileModel b) async {
    state = state.copyWith(
      isProcessing: true,
      clearSelection: true,
      comboCount: 0,
      isInvalidSwapFeedback: false,
    );

    final swappedBoard = state.board.swapTiles(a.row, a.col, b.row, b.col);
    final matches = MatchDetector.findMatches(swappedBoard);

    if (matches.isEmpty) {
      // Invalid move: show the swap briefly, then bounce back with a
      // bouncier curve (GridWidget reads isInvalidSwapFeedback for this).
      state = state.copyWith(board: swappedBoard);
      await Future.delayed(_swapDuration);
      state = state.copyWith(
        board: swappedBoard.swapTiles(a.row, a.col, b.row, b.col),
        isProcessing: false,
        isInvalidSwapFeedback: true,
      );
      return;
    }

    // Valid move: consumes one of the level's move budget.
    state = state.copyWith(
      board: swappedBoard,
      movesRemaining: state.movesRemaining - 1,
    );
    await Future.delayed(_swapDuration);

    await _resolveCascade();
    await _checkWinLose();

    if (state.status == GameStatus.playing) {
      await _reshuffleIfStuck();
    }

    state = state.copyWith(isProcessing: false);
  }

  /// Repeatedly: mark matches -> score them -> clear -> gravity ->
  /// refill (with a spawn-from-above entry animation) -> re-check.
  Future<void> _resolveCascade() async {
    var combo = 0;

    while (true) {
      final matches = MatchDetector.findMatches(state.board);
      if (matches.isEmpty) break;

      combo++;
      final pointsThisPass = matches.length * _pointsPerTile * combo;

      state = state.copyWith(
        board: state.board.markMatched(matches),
        comboCount: combo,
        score: state.score + pointsThisPass,
      );
      await Future.delayed(_matchPauseDuration);

      final cleared = state.board.clearMatched();
      final fallen = cleared.applyGravity();
      final refilled = fallen.refill(_random);

      // Phase 6: place new tiles above the board first, then let them
      // animate down to their real positions on the next state update.
      final entryBoard = _withSpawnEntryOffsets(fallen, refilled);
      state = state.copyWith(board: entryBoard);
      await Future.delayed(_spawnEntryFrameDelay);

      state = state.copyWith(board: refilled);
      await Future.delayed(_cascadeStepDuration);
    }

    if (combo >= _bigComboThreshold) {
      state = state.copyWith(shakeTrigger: state.shakeTrigger + 1);
    }
  }

  /// For every cell that was empty in [before] and now holds a tile in
  /// [after], returns a board where that tile's *visual* row (used only
  /// by GridWidget for positioning) is pushed above the board, stacked
  /// in column order. The grid's logical position (its index in
  /// `board.grid`, which is what match/gravity logic reads) is
  /// unchanged — only the animation start point differs.
  BoardModel _withSpawnEntryOffsets(BoardModel before, BoardModel after) {
    var result = after;

    for (var col = 0; col < after.cols; col++) {
      var newCount = 0;
      for (var row = 0; row < after.rows; row++) {
        if (before.tileAt(row, col) == null) {
          newCount++;
        } else {
          break; // gravity guarantees empties are a contiguous top run
        }
      }

      for (var row = 0; row < newCount; row++) {
        final tile = after.tileAt(row, col);
        if (tile == null) continue;
        result = result.withTile(row, col, tile.copyWith(row: row - newCount));
      }
    }

    return result;
  }

  Future<void> _checkWinLose() async {
    if (state.score >= state.level.targetScore) {
      state = state.copyWith(status: GameStatus.won);
    } else if (state.movesRemaining <= 0) {
      state = state.copyWith(status: GameStatus.lost);
    }
  }

  /// If no adjacent swap on the current board would produce a match,
  /// silently regenerates the board so the player is never stuck.
  Future<void> _reshuffleIfStuck() async {
    if (_hasAnyPossibleMove(state.board)) return;

    var attempts = 0;
    var candidate = BoardModel.generateRandom(
      rows: state.board.rows,
      cols: state.board.cols,
      random: _random,
    );
    while (!_hasAnyPossibleMove(candidate) && attempts < 10) {
      candidate = BoardModel.generateRandom(
        rows: state.board.rows,
        cols: state.board.cols,
        random: _random,
      );
      attempts++;
    }

    state = state.copyWith(board: candidate);
  }

  bool _hasAnyPossibleMove(BoardModel board) {
    for (var row = 0; row < board.rows; row++) {
      for (var col = 0; col < board.cols; col++) {
        if (col < board.cols - 1 &&
            MatchDetector.wouldCreateMatch(board, row, col, row, col + 1)) {
          return true;
        }
        if (row < board.rows - 1 &&
            MatchDetector.wouldCreateMatch(board, row, col, row + 1, col)) {
          return true;
        }
      }
    }
    return false;
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(),
);
