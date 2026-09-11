/// Defines a single level's identity, win condition, and constraints.
///
/// Hardcoded to a static list for now (see `core/constants/level_definitions.dart`)
/// — Phase 10 moves this into data-driven JSON level files and adds a
/// level loader. Keeping the shape of this class stable now means
/// Phase 10 mostly just adds a `fromJson`, not a rewrite.
class LevelConfig {
  final int id;
  final String title;
  final int moveLimit;
  final int targetScore;

  const LevelConfig({
    required this.id,
    required this.title,
    this.moveLimit = 20,
    this.targetScore = 1000,
  });

  static const LevelConfig defaultLevel = LevelConfig(id: 1, title: 'Level 1');
}

/// Overall state of the current level attempt.
enum GameStatus { playing, won, lost }
