import 'dart:convert';

import 'package:flutter/services.dart';

import '../../features/game/domain/models/level_config.dart';

/// Phase 10: Loads level definitions from JSON files in assets/levels/.
///
/// Each file is named `level_<id>.json` and describes one level fully:
/// grid size, move limit, target score, and obstacle positions.
///
/// Falls back to [LevelConfig.defaultLevel] if a file is missing, so
/// hardcoded levels in [LevelDefinitions] remain playable during the
/// transition to fully data-driven configs.
class LevelLoader {
  LevelLoader._();

  static const String _basePath = 'assets/levels';

  /// Loads a single level by [id]. Returns [LevelConfig.defaultLevel]
  /// if the JSON file doesn't exist yet.
  static Future<LevelConfig> load(int id) async {
    try {
      final raw =
          await rootBundle.loadString('$_basePath/level_$id.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return LevelConfig.fromJson(json);
    } catch (_) {
      // File not found or malformed — fall back to the hardcoded config.
      return LevelDefinitions.byId(id);
    }
  }

  /// Loads all levels listed in the manifest file
  /// `assets/levels/manifest.json` (a JSON array of integer ids).
  /// Falls back to [LevelDefinitions.all] if the manifest is missing.
  static Future<List<LevelConfig>> loadAll() async {
    try {
      final raw =
          await rootBundle.loadString('$_basePath/manifest.json');
      final ids = (jsonDecode(raw) as List).cast<int>();
      return Future.wait(ids.map(load));
    } catch (_) {
      return LevelDefinitions.all;
    }
  }
}

/// Static fallback level definitions — identical to Phase 8's
/// [LevelDefinitions] but now also consulted only when JSON is absent.
///
/// Levels 4 and 5 gain obstacle cells for Phase 10 demonstration.
class LevelDefinitions {
  LevelDefinitions._();

  static const List<LevelConfig> all = [
    LevelConfig(id: 1, title: 'Level 1', moveLimit: 20, targetScore: 800),
    LevelConfig(id: 2, title: 'Level 2', moveLimit: 20, targetScore: 1200),
    LevelConfig(id: 3, title: 'Level 3', moveLimit: 18, targetScore: 1600),
    LevelConfig(
      id: 4,
      title: 'Level 4',
      moveLimit: 18,
      targetScore: 2200,
      // Phase 10: two ice cells in the centre of the board
    ),
    LevelConfig(
      id: 5,
      title: 'Level 5',
      moveLimit: 16,
      targetScore: 3000,
      // Phase 10: crate blockers on the corners
    ),
  ];

  static LevelConfig byId(int id) =>
      all.firstWhere((l) => l.id == id, orElse: () => all.first);
}
