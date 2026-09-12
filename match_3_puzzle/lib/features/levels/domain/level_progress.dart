/// A player's progress on one level: whether it's unlocked, their best
/// star rating, and their best score.
///
/// Phase 10: [toJson]/[fromJson] added so [LevelsNotifier] can persist
/// the full list via shared_preferences/Hive without changing this
/// class's public interface.
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

  // Phase 10 ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'isUnlocked': isUnlocked,
        'stars': stars,
        'bestScore': bestScore,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        levelId: json['levelId'] as int,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        stars: json['stars'] as int? ?? 0,
        bestScore: json['bestScore'] as int? ?? 0,
      );
}
