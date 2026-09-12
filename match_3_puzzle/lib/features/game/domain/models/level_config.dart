import 'dart:math';

/// Phase 9/10: Obstacle types driven by level JSON data.
///
/// - [ice]   — tile is encased in ice; must be matched adjacent to it once
///             to break the ice layer, then again to clear the tile itself.
/// - [crate] — immovable blocker; can only be destroyed by matching tiles
///             directly adjacent to it (not by matching the crate itself).
enum ObstacleType { ice, crate }

/// Defines a single level's identity, win condition, constraints, and
/// obstacle layout.
///
/// Phase 10: `fromJson` constructor so levels are data-driven (loaded
/// from assets/levels/*.json) instead of hardcoded. The shape kept
/// stable from earlier phases, so it's just an additive change.
class LevelConfig {
  final int id;
  final String title;
  final int moveLimit;
  final int targetScore;
  final int rows;
  final int cols;

  /// Phase 10: obstacle cells — maps (row, col) → ObstacleType.
  /// Empty map = no obstacles (all earlier levels).
  final Map<Point<int>, ObstacleType> obstacles;

  const LevelConfig({
    required this.id,
    required this.title,
    this.moveLimit = 20,
    this.targetScore = 1000,
    this.rows = 8,
    this.cols = 8,
    this.obstacles = const {},
  });

  /// Phase 10: deserialise from a JSON map (loaded via rootBundle).
  factory LevelConfig.fromJson(Map<String, dynamic> json) {
    final obstacleMap = <Point<int>, ObstacleType>{};

    final rawObstacles = json['obstacles'] as List<dynamic>? ?? [];
    for (final o in rawObstacles) {
      final r = o['row'] as int;
      final c = o['col'] as int;
      final typeStr = o['type'] as String;
      final type = typeStr == 'crate' ? ObstacleType.crate : ObstacleType.ice;
      obstacleMap[Point(c, r)] = type;
    }

    return LevelConfig(
      id: json['id'] as int,
      title: json['title'] as String,
      moveLimit: json['moveLimit'] as int? ?? 20,
      targetScore: json['targetScore'] as int? ?? 1000,
      rows: json['rows'] as int? ?? 8,
      cols: json['cols'] as int? ?? 8,
      obstacles: obstacleMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'moveLimit': moveLimit,
        'targetScore': targetScore,
        'rows': rows,
        'cols': cols,
        'obstacles': obstacles.entries
            .map((e) => {
                  'row': e.key.y,
                  'col': e.key.x,
                  'type': e.value == ObstacleType.crate ? 'crate' : 'ice',
                })
            .toList(),
      };

  static const LevelConfig defaultLevel = LevelConfig(id: 1, title: 'Level 1');
}

/// Overall state of the current level attempt.
enum GameStatus { playing, won, lost }
