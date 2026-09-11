import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/level_definitions.dart';
import '../domain/level_progress.dart';

/// Tracks unlock/star/best-score progress for every level in
/// [LevelDefinitions.all]. Level 1 starts unlocked; every other level
/// unlocks the moment the previous one is completed.
class LevelsNotifier extends StateNotifier<List<LevelProgress>> {
  LevelsNotifier()
      : super([
          for (final level in LevelDefinitions.all)
            LevelProgress(levelId: level.id, isUnlocked: level.id == 1),
        ]);

  LevelProgress progressFor(int levelId) =>
      state.firstWhere((p) => p.levelId == levelId);

  /// Computes a 0-3 star rating from how far past the target the final
  /// score landed, then records it (keeping the best result) and
  /// unlocks the next level.
  int recordResult(int levelId, int score, int targetScore) {
    final stars = _starsFor(score, targetScore);

    state = [
      for (final p in state)
        if (p.levelId == levelId)
          p.copyWith(
            stars: stars > p.stars ? stars : p.stars,
            bestScore: score > p.bestScore ? score : p.bestScore,
            isUnlocked: true,
          )
        else if (p.levelId == levelId + 1)
          p.copyWith(isUnlocked: true)
        else
          p,
    ];

    return stars;
  }

  int _starsFor(int score, int targetScore) {
    if (score >= targetScore * 2) return 3;
    if (score >= (targetScore * 1.5).round()) return 2;
    if (score >= targetScore) return 1;
    return 0;
  }
}

final levelsProvider =
    StateNotifierProvider<LevelsNotifier, List<LevelProgress>>(
  (ref) => LevelsNotifier(),
);
