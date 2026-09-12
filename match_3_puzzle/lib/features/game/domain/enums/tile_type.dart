import 'package:flutter/material.dart';

/// The set of tile "colors"/kinds a normal tile can be.
///
/// Phase 9 adds [SpecialTileType] below — kept separate so match-detection
/// logic (which only ever sees normal tile types) never needs to change.
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

/// Phase 9: Special tile variants created from bigger matches.
///
/// - [striped] — created from a match-4. Direction (H/V) is stored on
///   the tile itself. Clears its entire row or column when activated.
/// - [wrapped] — created from an L/T-shaped match. Clears a 3×3 area
///   centred on itself when activated (twice: once on swap, once on clear).
/// - [colorBomb] — created from a match-5. Clears every tile of the color
///   it is swapped with (or a random color if activated alone).
enum SpecialTileType { striped, wrapped, colorBomb }

extension SpecialTileTypeX on SpecialTileType {
  Color get overlayColor {
    switch (this) {
      case SpecialTileType.striped:
        return Colors.white.withOpacity(0.35);
      case SpecialTileType.wrapped:
        return Colors.white.withOpacity(0.25);
      case SpecialTileType.colorBomb:
        return Colors.white.withOpacity(0.15);
    }
  }

  IconData get overlayIcon {
    switch (this) {
      case SpecialTileType.striped:
        return Icons.more_horiz;
      case SpecialTileType.wrapped:
        return Icons.all_inclusive;
      case SpecialTileType.colorBomb:
        return Icons.blur_circular;
    }
  }
}

/// Stripe direction for [SpecialTileType.striped] tiles.
enum StripeDirection { horizontal, vertical }
