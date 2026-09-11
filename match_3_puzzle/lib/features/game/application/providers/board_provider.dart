import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_providers.dart';
import '../../../../core/audio/sfx.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../settings/application/settings_provider.dart';
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
  final bool isPaused;
  final int comboCount;

  /// True only for the single state update where a swap is being
  /// reverted (no match). GridWidget uses this to pick a bouncier curve
  /// for that one transition.
  final bool isInvalidSwapFeedback;

  /// Bumped (never reset) whenever a cascade combo reaches 3+ passes,
  /// so a listener (ShakeWidget) can replay a shake purely by diffing
  /// this value.
  final int shakeTrigger;

  final int score;
  final int movesRemaining;
  final GameStatus status;

  const GameState({
    required this.board,
    required this.level,
    this.selectedTileId,
    this.isProcessing = false,
    this.isPaused = false,
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
    bool? isPaused,
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
      isPaused: isPaused ?? this.isPaused,
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
/// Phase 5: scoring, move limit, win/lose, "no possible moves" auto-reshuffle.
/// Phase 6: spawn-from-above entry animation, invalid-swap bounce flag,
///          big-combo shake trigger.
/// Phase 7: takes its starting [LevelConfig] directly, supports pause/resume.
/// Phase 8: plays SFX + haptics at each of those same event points,
///          gated by the user's settings toggles (hence the [Ref]).
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier(this._ref, LevelConfig level)
      : super(
          GameState(
            board: BoardModel.generateRandom(
              rows: BoardConfig.rows,
              cols: BoardConfig.cols,
            ),
            level: level,
            movesRemaining: level.moveLimit,
          ),
        );

  final Ref _ref;
  final Random _random = Random();

  static const _swapDuration = Duration(milliseconds: 220);
  static const _matchPauseDuration = Duration(milliseconds: 200);
  static const _cascadeStepDuration = Duration(milliseconds: 260);

  /// One frame's worth of delay so the "entry" (spawn-above) board
  /// actually paints before we jump to the settled positions.
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

  void pause() {
    if (state.status != GameStatus.playing) return;
    state = state.copyWith(isPaused: true);
  }

  void resume() => state = state.copyWith(isPaused: false);

  Future<void> onTileTapped(TileModel tile) async {
    if (state.isProcessing || state.isPaused) return;
    if (state.status != GameStatus.playing) return;

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
      _playSfx(SfxType.invalidMove);
      _haptic(HapticFeedback.selectionClick);

      state = state.copyWith(board: swappedBoard);
      await Future.delayed(_swapDuration);
      state = state.copyWith(
        board: swappedBoard.swapTiles(a.row, a.col, b.row, b.col),
        isProcessing: false,
        isInvalidSwapFeedback: true,
      );
      return;
    }

    _playSfx(SfxType.swap);
    _haptic(HapticFeedback.lightImpact);

    state = state.copyWith(
      board: swappedBoard,
      movesRemaining: state.movesRemaining - 1,
    );
    await Future.delayed(_swapDuration);

    await _resolveCascade();
    _checkWinLose();

    if (state.status == GameStatus.playing) {
      await _reshuffleIfStuck();
    }

    state = state.copyWith(isProcessing: false);
  }

  /// Repeatedly: mark matches -> score them -> clear -> gravity ->
  /// refill (spawn-from-above) -> re-check.
  Future<void> _resolveCascade() async {
    var combo = 0;

    while (true) {
      final matches = MatchDetector.findMatches(state.board);
      if (matches.isEmpty) break;

      combo++;
      final pointsThisPass = matches.length * _pointsPerTile * combo;

      _playSfx(combo > 1 ? SfxType.combo : SfxType.match);
      _haptic(HapticFeedback.mediumImpact);

      state = state.copyWith(
        board: state.board.markMatched(matches),
        comboCount: combo,
        score: state.score + pointsThisPass,
      );
      await Future.delayed(_matchPauseDuration);

      final cleared = state.board.clearMatched();
      final fallen = cleared.applyGravity();
      final refilled = fallen.refill(_random);

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

  BoardModel _withSpawnEntryOffsets(BoardModel before, BoardModel after) {
    var result = after;

    for (var col = 0; col < after.cols; col++) {
      var newCount = 0;
      for (var row = 0; row < after.rows; row++) {
        if (before.tileAt(row, col) == null) {
          newCount++;
        } else {
          break;
        }
      }

      for (var row = 0; row < newCount; row++) {
        final tile = after.tileAt(row, col);
        if (tile == null) continue;
        result =
            result.withTile(row, col, tile.copyWith(row: row - newCount));
      }
    }

    return result;
  }

  void _checkWinLose() {
    if (state.score >= state.level.targetScore) {
      state = state.copyWith(status: GameStatus.won);
      _playSfx(SfxType.win);
      _haptic(HapticFeedback.heavyImpact);
    } else if (state.movesRemaining <= 0) {
      state = state.copyWith(status: GameStatus.lost);
      _playSfx(SfxType.lose);
      _haptic(HapticFeedback.heavyImpact);
    }
  }

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

  void _playSfx(SfxType sfx) {
    if (!_ref.read(settingsProvider).soundEnabled) return;
    _ref.read(audioServiceProvider).playSfx(sfx);
  }

  void _haptic(Future<void> Function() hapticCall) {
    if (!_ref.read(settingsProvider).vibrationEnabled) return;
    hapticCall();
  }
}

/// `.autoDispose` so leaving a level screen (back to the level map)
/// discards that attempt's state instead of leaking a GameNotifier per
/// level for the lifetime of the app. `.family` keyed by [LevelConfig]
/// gives each level its own isolated game state — safe because
/// `LevelConfig` instances always come from the same `const` list in
/// [LevelDefinitions], so identity equality is stable across rebuilds.
final gameProvider = StateNotifierProvider.autoDispose
    .family<GameNotifier, GameState, LevelConfig>(
  (ref, level) => GameNotifier(ref, level),
);
