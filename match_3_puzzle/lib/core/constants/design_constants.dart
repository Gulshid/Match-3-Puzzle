import 'package:flutter/material.dart';

/// Central place for layout + responsiveness constants.
///
/// Mirrors the responsive pattern from our other Flutter apps:
/// ScreenUtilInit design size is picked based on the *current* width from
/// LayoutBuilder, so text/paddings/radii scale sensibly across
/// phone / tablet / desktop without shipping three separate layouts.
class DesignConstants {
  DesignConstants._();

  /// Phone design size (matches ToneFix's baseline).
  static const Size phone = Size(360, 800);

  /// Tablet design size.
  static const Size tablet = Size(834, 1194);

  /// Desktop / large-screen design size.
  static const Size desktop = Size(1440, 1024);

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1200;

  /// Returns the ScreenUtil design size for a given available width.
  static Size designSizeFor(double width) {
    if (width < tabletBreakpoint) return phone;
    if (width < desktopBreakpoint) return tablet;
    return desktop;
  }
}

/// Board/grid configuration. Kept separate from DesignConstants because
/// this is gameplay config (will later move into per-level JSON in
/// Phase 10), not layout config.
class BoardConfig {
  BoardConfig._();

  static const int rows = 8;
  static const int cols = 8;

  /// Space between tiles, in logical pixels *before* ScreenUtil scaling.
  static const double tileSpacing = 4;

  /// Corner radius for tiles.
  static const double tileRadius = 12;
}
