import 'package:flutter/material.dart';

/// The set of tile "colors"/kinds a normal tile can be.
///
/// Special tiles (striped, wrapped, color bomb) are added in Phase 9 —
/// keeping this enum to plain colors for now keeps match-detection simple.
enum TileType { red, blue, green, yellow, purple, orange }

extension TileTypeX on TileType {
  Color get color {
    switch (this) {
      case TileType.red:
        return const Color(0xFFE85D5D);
      case TileType.blue:
        return const Color(0xFF4E8CE8);
      case TileType.green:
        return const Color(0xFF4EC97F);
      case TileType.yellow:
        return const Color(0xFFE8C34E);
      case TileType.purple:
        return const Color(0xFF9B6BE8);
      case TileType.orange:
        return const Color(0xFFE88A4E);
    }
  }

  IconData get icon {
    switch (this) {
      case TileType.red:
        return Icons.favorite;
      case TileType.blue:
        return Icons.water_drop;
      case TileType.green:
        return Icons.eco;
      case TileType.yellow:
        return Icons.star;
      case TileType.purple:
        return Icons.diamond;
      case TileType.orange:
        return Icons.local_fire_department;
    }
  }
}
