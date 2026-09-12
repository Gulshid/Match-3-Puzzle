import 'package:flutter/material.dart';

/// Candy-glossy palette shared by every screen.
///
/// Everything visual in the app now pulls from here instead of
/// hardcoded `Color(0x...)` literals, so the whole look can be
/// re-skinned from one place.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────
  static const Color candyPink = Color(0xFFFF5FA2);
  static const Color candyPurple = Color(0xFF8A5CFF);
  static const Color candyBlue = Color(0xFF3FC1FF);
  static const Color candyMint = Color(0xFF34E4B0);
  static const Color candyOrange = Color(0xFFFF9C4A);
  static const Color candyYellow = Color(0xFFFFD84A);

  // ── Backgrounds ─────────────────────────────────────────────────
  static const List<Color> skyLight = [
    Color(0xFF8F6BFF),
    Color(0xFF5C7CFA),
    Color(0xFF3FC1FF),
  ];

  static const List<Color> skyDark = [
    Color(0xFF120B29),
    Color(0xFF221347),
    Color(0xFF3A1B5C),
  ];

  static const List<Color> boardFrameLight = [
    Color(0xFF6A3FBF),
    Color(0xFF4A2A94),
  ];

  static const List<Color> boardFrameDark = [
    Color(0xFF1B1030),
    Color(0xFF0E081C),
  ];

  // ── Glass / surfaces ────────────────────────────────────────────
  static Color glass(Brightness b, {double opacity = 0.16}) =>
      (b == Brightness.dark ? Colors.white : Colors.white)
          .withOpacity(opacity);

  static Color glassBorder(Brightness b) =>
      Colors.white.withOpacity(b == Brightness.dark ? 0.22 : 0.55);

  // ── Misc ────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFFFC93C);
  static const Color emberRed = Color(0xFFFF5C5C);

  static const Color seed = candyPurple;
}
