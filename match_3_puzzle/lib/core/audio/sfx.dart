/// Sound-effect identifiers, decoupled from their asset paths.
///
/// Phase 9 adds: [specialCreated], [striped], [wrapped], [colorBomb].
/// Phase 8 sounds remain unchanged.
enum SfxType {
  swap,
  invalidMove,
  match,
  combo,
  win,
  lose,
  // Phase 9
  specialCreated,
  striped,
  wrapped,
  colorBomb,
}

extension SfxTypeAsset on SfxType {
  /// Path relative to the `assets/` folder (AssetSource wants it
  /// without the leading `assets/`).
  String get assetPath {
    switch (this) {
      case SfxType.swap:
        return 'sounds/swap.mp3';
      case SfxType.invalidMove:
        return 'sounds/invalid.mp3';
      case SfxType.match:
        return 'sounds/match.mp3';
      case SfxType.combo:
        return 'sounds/combo.mp3';
      case SfxType.win:
        return 'sounds/win.mp3';
      case SfxType.lose:
        return 'sounds/lose.mp3';
      // Phase 9 — reuse existing sounds so nothing crashes before
      // dedicated assets are added. Swap with unique files whenever ready.
      case SfxType.specialCreated:
        return 'sounds/combo.mp3';
      case SfxType.striped:
        return 'sounds/match.mp3';
      case SfxType.wrapped:
        return 'sounds/combo.mp3';
      case SfxType.colorBomb:
        return 'sounds/win.mp3';
    }
  }
}
