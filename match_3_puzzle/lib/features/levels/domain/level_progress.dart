/// A player's progress on one level: whether it's unlocked, their best
/// star rating, and their best score. In-memory only for now — Phase 10
/// persists this list via shared_preferences/Hive.
class LevelProgress {
  final int levelId;
  final bool isUnlocked;
  final int stars; // 0-3
  final int bestScore;

  const LevelProgress({
    required this.levelId,
    this.isUnlocked = false,
    this.stars = 0,
    this.bestScore = 0,
  });

  LevelProgress copyWith({
    bool? isUnlocked,
    int? stars,
    int? bestScore,
  }) {
    return LevelProgress(
      levelId: levelId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      stars: stars ?? this.stars,
      bestScore: bestScore ?? this.bestScore,
    );
  }
}
