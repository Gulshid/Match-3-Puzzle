/// Defines a single level's win condition and constraints.
///
/// Hardcoded to one default level for now — Phase 10 moves this into
/// data-driven JSON level files and adds a level loader. Keeping the
/// shape of this class stable now means Phase 10 mostly just adds a
/// `fromJson`, not a rewrite.
class LevelConfig {
  final int moveLimit;
  final int targetScore;

  const LevelConfig({
    this.moveLimit = 20,
    this.targetScore = 1000,
  });

  static const LevelConfig defaultLevel = LevelConfig();
}

/// Overall state of the current level attempt.
enum GameStatus { playing, won, lost }
