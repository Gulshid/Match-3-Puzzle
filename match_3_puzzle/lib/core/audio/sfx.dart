/// Sound-effect identifiers, decoupled from their asset paths so the
/// rest of the app never deals with raw file strings.
///
/// IMPORTANT: these paths point at files that are NOT included — you
/// need to add your own short SFX clips at these paths and list them
/// under `flutter/assets` in pubspec.yaml (already done in the pubspec
/// update for this phase). Until you do, [AudioService] silently no-ops
/// (see its try/catch) rather than crashing gameplay.
enum SfxType { swap, invalidMove, match, combo, win, lose }

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
    }
  }
}
