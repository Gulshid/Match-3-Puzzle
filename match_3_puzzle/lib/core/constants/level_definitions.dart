import '../../features/game/domain/models/level_config.dart';

/// The game's level list. Static/hardcoded for now — Phase 10 replaces
/// this with a JSON-driven level loader, but every other Phase 7 screen
/// (level select, HUD, result overlay) only depends on `LevelConfig`
/// itself, so that swap will be contained to this file.
class LevelDefinitions {
  LevelDefinitions._();

  static const List<LevelConfig> all = [
    LevelConfig(id: 1, title: 'Level 1', moveLimit: 20, targetScore: 800),
    LevelConfig(id: 2, title: 'Level 2', moveLimit: 20, targetScore: 1200),
    LevelConfig(id: 3, title: 'Level 3', moveLimit: 18, targetScore: 1600),
    LevelConfig(id: 4, title: 'Level 4', moveLimit: 18, targetScore: 2200),
    LevelConfig(id: 5, title: 'Level 5', moveLimit: 16, targetScore: 3000),
  ];

  static LevelConfig byId(int id) =>
      all.firstWhere((l) => l.id == id, orElse: () => all.first);
}
