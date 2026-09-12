import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_providers.dart';
import '../../../../core/audio/sfx.dart';
import '../../../settings/application/settings_provider.dart';
import '../../domain/enums/tile_type.dart';
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
  final bool isInvalidSwapFeedback;
  final int shakeTrigger;
  final int score;
  final int movesRemaining;
  final GameStatus status;

  /// Phase 9: tile id that just activated as a special — widgets use
  /// this to show a momentary flash before the effect fires.
  final String? activatingSpecialId;

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
    this.activatingSpecialId,
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
    String? activatingSpecialId,
    bool clearActivatingSpecial = false,
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
      activatingSpecialId: clearActivatingSpecial
          ? null
          : (activatingSpecialId ?? this.activatingSpecialId),
    );
  }
}

/// Owns the board and all swap/match/cascade/scoring/special-tile logic.
///
/// Phase 9: special tile creation on match-4/5/L-T, activation on swap,
///          combo effects for two specials swapped together.
/// Phase 10: [LevelConfig] now sourced from JSON (via [LevelLoader]),
///           obstacle tiles (ice, crates) participate in match logic.
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier(this._ref, LevelConfig level)
      : super(
          GameState(
            board: BoardModel.generateRandom(
              rows: level.rows,
              cols: level.cols,
              obstacles: level.obstacles,
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
  static const _spawnEntryFrameDelay = Duration(milliseconds: 32);
  static const _specialFlashDuration = Duration(milliseconds: 320);

  static const int _bigComboThreshold = 3;
  static const int _pointsPerTile = 10;
  static const int _specialBonus = 50;

  // ─── Public API ───────────────────────────────────────────────────

  void newGame({LevelConfig? level}) {
    final newLevel = level ?? state.level;
    state = GameState(
      board: BoardModel.generateRandom(
        rows: newLevel.rows,
        cols: newLevel.cols,
        random: _random,
        obstacles: newLevel.obstacles,
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

  // ─── Core swap logic ──────────────────────────────────────────────

  Future<void> _trySwap(TileModel a, TileModel b) async {
    state = state.copyWith(
      isProcessing: true,
      clearSelection: true,
      comboCount: 0,
      isInvalidSwapFeedback: false,
      clearActivatingSpecial: true,
    );

    final swappedBoard = state.board.swapTiles(a.row, a.col, b.row, b.col);

    // Phase 9: if either tile is a special, activate it immediately
    // regardless of whether the swap creates a match.
    final aSpecial = a.isSpecial;
    final bSpecial = b.isSpecial;

    if (aSpecial || bSpecial) {
      await _handleSpecialSwap(swappedBoard, a, b);
      state = state.copyWith(
        movesRemaining: state.movesRemaining - 1,
        isProcessing: false,
      );
      _checkWinLose();
      return;
    }

    // Normal swap path.
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

  // ─── Phase 9: Special tile activation ─────────────────────────────

  /// Handles a swap where at least one tile is special.
  /// Two specials swapped together combine their effects.
  Future<void> _handleSpecialSwap(
    BoardModel swappedBoard,
    TileModel a,
    TileModel b,
  ) async {
    state = state.copyWith(board: swappedBoard);
    await Future.delayed(_swapDuration);

    var board = swappedBoard;
    var bonusScore = 0;
    var extraPositions = <Point<int>>{};

    // Flash the activating tile(s).
    if (a.isSpecial) {
      state = state.copyWith(activatingSpecialId: a.id);
      _playSfx(_sfxForSpecial(a.specialType!));
    }
    if (b.isSpecial) {
      state = state.copyWith(activatingSpecialId: b.id);
      _playSfx(_sfxForSpecial(b.specialType!));
    }
    await Future.delayed(_specialFlashDuration);

    // Collect positions from both specials.
    if (a.isSpecial) {
      final pos = board.activateSpecialAt(
        a.row, a.col, board,
        swappedWithType: b.type,
      );
      extraPositions.addAll(pos);
      bonusScore += _specialBonus;
    }
    if (b.isSpecial) {
      final pos = board.activateSpecialAt(
        b.row, b.col, board,
        swappedWithType: a.type,
      );
      extraPositions.addAll(pos);
      bonusScore += _specialBonus;
    }

    if (extraPositions.isNotEmpty) {
      board = board.markMatched(extraPositions);
      state = state.copyWith(
        board: board,
        score: state.score + extraPositions.length * _pointsPerTile + bonusScore,
        clearActivatingSpecial: true,
      );
      await Future.delayed(_matchPauseDuration);

      board = board.clearMatched();
      board = board.clearAdjacentCrates(extraPositions);
      board = board.applyGravity();
      final entryBoard = _withSpawnEntryOffsets(board, board.refill(_random));
      state = state.copyWith(board: entryBoard);
      await Future.delayed(_spawnEntryFrameDelay);
      board = board.refill(_random);
      state = state.copyWith(board: board);
      await Future.delayed(_cascadeStepDuration);
    }

    // Continue with regular cascade (chain reactions).
    await _resolveCascade();
    _checkWinLose();
  }

  // ─── Cascade loop ─────────────────────────────────────────────────

  Future<void> _resolveCascade() async {
    var combo = 0;

    while (true) {
      final matchResults = MatchDetector.findMatchResults(state.board);
      if (matchResults.isEmpty) break;

      combo++;
      final allPositions = <Point<int>>{};
      for (final r in matchResults) {
        allPositions.addAll(r.positions);
      }

      final pointsThisPass =
          allPositions.length * _pointsPerTile * combo;

      _playSfx(combo > 1 ? SfxType.combo : SfxType.match);
      _haptic(HapticFeedback.mediumImpact);

      // Mark matched tiles.
      var board = state.board.markMatched(allPositions);

      // Phase 9: spawn special tiles at designated pivot cells
      // (before clearing, so the spawned tile animates into place).
      for (final result in matchResults) {
        if (result.specialSpawnAt != null && result.specialType != null) {
          final p = result.specialSpawnAt!;
          board = board.spawnSpecialAt(
            p.y, // row
            p.x, // col
            result.specialType!,
            stripeDirection: result.stripeDirection,
          );
          _playSfx(SfxType.specialCreated);
        }
      }

      state = state.copyWith(
        board: board,
        comboCount: combo,
        score: state.score + pointsThisPass,
      );
      await Future.delayed(_matchPauseDuration);

      // Phase 10: clear matched tiles + break adjacent obstacles.
      var cleared = state.board.clearMatched();
      cleared = cleared.clearAdjacentCrates(allPositions);
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

  // ─── Helpers ──────────────────────────────────────────────────────

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
      obstacles: state.level.obstacles,
    );
    while (!_hasAnyPossibleMove(candidate) && attempts < 10) {
      candidate = BoardModel.generateRandom(
        rows: state.board.rows,
        cols: state.board.cols,
        random: _random,
        obstacles: state.level.obstacles,
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

  void _playSfx(SfxType sfx) {
    if (!_ref.read(settingsProvider).soundEnabled) return;
    _ref.read(audioServiceProvider).playSfx(sfx);
  }

  void _haptic(Future<void> Function() hapticCall) {
    if (!_ref.read(settingsProvider).vibrationEnabled) return;
    hapticCall();
  }

  SfxType _sfxForSpecial(SpecialTileType type) {
    switch (type) {
      case SpecialTileType.striped:
        return SfxType.striped;
      case SpecialTileType.wrapped:
        return SfxType.wrapped;
      case SpecialTileType.colorBomb:
        return SfxType.colorBomb;
    }
  }
}

final gameProvider = StateNotifierProvider.autoDispose
    .family<GameNotifier, GameState, LevelConfig>(
  (ref, level) => GameNotifier(ref, level),
);
