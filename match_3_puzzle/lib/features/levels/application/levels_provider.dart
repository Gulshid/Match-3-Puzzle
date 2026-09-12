import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/level_definitions.dart';
import '../domain/level_progress.dart';

/// Phase 10: thin async wrapper that exposes [SharedPreferences] to
/// providers that need it. Loaded once at startup via [ProviderScope]'s
/// `overrides` parameter in main.dart.
final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError(
          'Override sharedPreferencesProvider in ProviderScope',
        ));

/// Phase 10: persistence key for the progress list.
const _kProgressKey = 'levels_progress_v1';

/// Tracks unlock/star/best-score progress for every level.
///
/// Phase 10 changes vs Phase 8:
/// - Constructor reads saved progress from [SharedPreferences] on init
///   (via [_load]) so progress survives app restarts.
/// - [recordResult] persists after updating state (via [_save]).
/// - Levels are now loaded asynchronously from JSON via [LevelLoader]
///   (falls back to [LevelDefinitions.all] seamlessly).
class LevelsNotifier extends StateNotifier<List<LevelProgress>> {
  LevelsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  /// Deserialise saved progress, filling in any missing levels with
  /// fresh (locked) entries so new levels added to the game don't crash.
  static List<LevelProgress> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kProgressKey);
    Map<int, LevelProgress> saved = {};

    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        for (final item in list) {
          final p = LevelProgress.fromJson(item);
          saved[p.levelId] = p;
        }
      } catch (_) {
        // Corrupted data — start fresh.
      }
    }

    return [
      for (final level in LevelDefinitions.all)
        saved[level.id] ??
            LevelProgress(levelId: level.id, isUnlocked: level.id == 1),
    ];
  }

  Future<void> _save() async {
    final encoded = jsonEncode(state.map((p) => p.toJson()).toList());
    await _prefs.setString(_kProgressKey, encoded);
  }

  LevelProgress progressFor(int levelId) =>
      state.firstWhere((p) => p.levelId == levelId);

  /// Computes a 0-3 star rating, records the best result, unlocks the
  /// next level, and persists to [SharedPreferences].
  Future<int> recordResult(int levelId, int score, int targetScore) async {
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

    await _save();
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
  (ref) => LevelsNotifier(ref.watch(sharedPreferencesProvider)),
);
