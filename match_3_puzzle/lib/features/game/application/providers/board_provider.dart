import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/design_constants.dart';
import '../../domain/models/board_model.dart';
import '../../domain/models/tile_model.dart';
import '../../domain/services/match_detector.dart';

/// Everything the UI needs to render and interact with the board:
/// the board itself, which tile (if any) is currently selected, whether
/// a swap/cascade is mid-animation (used to block input), and the
/// current combo chain length.
class GameState {
  final BoardModel board;
  final String? selectedTileId;
  final bool isProcessing;
  final int comboCount;

  const GameState({
    required this.board,
    this.selectedTileId,
    this.isProcessing = false,
    this.comboCount = 0,
  });

  GameState copyWith({
    BoardModel? board,
    String? selectedTileId,
    bool clearSelection = false,
    bool? isProcessing,
    int? comboCount,
  }) {
    return GameState(
      board: board ?? this.board,
      selectedTileId:
          clearSelection ? null : (selectedTileId ?? this.selectedTileId),
      isProcessing: isProcessing ?? this.isProcessing,
      comboCount: comboCount ?? this.comboCount,
    );
  }
}

/// Owns the board and all swap/match/cascade logic.
///
/// Phase 3 added: tap-to-select, adjacency-restricted swapping, and
/// match detection with revert-on-invalid-swap.
/// Phase 4 added: the clear -> gravity -> refill -> re-check cascade
/// loop, with a combo counter tracking chain length.
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier()
      : super(
          GameState(
            board: BoardModel.generateRandom(
              rows: BoardConfig.rows,
              cols: BoardConfig.cols,
            ),
          ),
        );

  final Random _random = Random();

  // These durations drive the *timing* of state changes (so gravity has
  // "settled" before we re-check matches, etc). Real motion animation
  // lives in the widgets (Phase 6 will make it much juicier) — these
  // just need to roughly match the widgets' AnimatedPositioned duration.
  static const _swapDuration = Duration(milliseconds: 200);
  static const _matchPauseDuration = Duration(milliseconds: 180);
  static const _cascadeStepDuration = Duration(milliseconds: 220);

  void newGame() {
    state = GameState(
      board: BoardModel.generateRandom(
        rows: BoardConfig.rows,
        cols: BoardConfig.cols,
      ),
    );
  }

  /// Handles a tap on [tile]:
  /// - No tile selected yet -> select this one.
  /// - Tapping the already-selected tile -> deselect.
  /// - Tapping an adjacent tile -> attempt a swap.
  /// - Tapping a non-adjacent tile -> move the selection there instead.
  Future<void> onTileTapped(TileModel tile) async {
    if (state.isProcessing) return;

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
    );

    final swappedBoard = state.board.swapTiles(a.row, a.col, b.row, b.col);
    final matches = MatchDetector.findMatches(swappedBoard);

    if (matches.isEmpty) {
      // Invalid move: show the swap briefly, then bounce the tiles back.
      state = state.copyWith(board: swappedBoard);
      await Future.delayed(_swapDuration);
      state = state.copyWith(
        board: swappedBoard.swapTiles(a.row, a.col, b.row, b.col),
        isProcessing: false,
      );
      return;
    }

    state = state.copyWith(board: swappedBoard);
    await Future.delayed(_swapDuration);
    await _resolveCascade();
    state = state.copyWith(isProcessing: false);
  }

  /// Repeatedly: mark matches -> clear -> apply gravity -> refill ->
  /// re-check, until a pass finds no matches. `comboCount` tracks how
  /// many passes this chain took (2+ means a cascade combo happened).
  Future<void> _resolveCascade() async {
    var combo = 0;

    while (true) {
      final matches = MatchDetector.findMatches(state.board);
      if (matches.isEmpty) break;

      combo++;
      state = state.copyWith(
        board: state.board.markMatched(matches),
        comboCount: combo,
      );
      await Future.delayed(_matchPauseDuration);

      final cleared = state.board.clearMatched();
      final fallen = cleared.applyGravity();
      final refilled = fallen.refill(_random);

      state = state.copyWith(board: refilled);
      await Future.delayed(_cascadeStepDuration);
    }
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(),
);
