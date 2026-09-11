import 'package:audioplayers/audioplayers.dart';

import 'sfx.dart';

/// Thin wrapper around two [AudioPlayer]s — one for one-shot SFX, one
/// looping for background music — so the rest of the app never touches
/// `audioplayers` directly.
///
/// Every call is wrapped in try/catch: if the asset file listed in
/// [SfxTypeAsset.assetPath] hasn't been added yet, playback just fails
/// silently instead of throwing during gameplay. Swap in real audio
/// files under `assets/sounds/` whenever you have them — no code
/// changes needed.
class AudioService {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.loop);

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  void setSoundEnabled(bool enabled) => _soundEnabled = enabled;

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      await _musicPlayer.pause();
    } else {
      await _musicPlayer.resume();
    }
  }

  Future<void> playSfx(SfxType sfx) async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(sfx.assetPath));
    } catch (_) {
      // Missing/unadded asset — ignore so gameplay never crashes on this.
    }
  }

  Future<void> playMusic(String assetPath, {double volume = 0.4}) async {
    if (!_musicEnabled) return;
    try {
      await _musicPlayer.setVolume(volume);
      await _musicPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // Missing/unadded asset — ignore.
    }
  }

  Future<void> stopMusic() => _musicPlayer.stop();

  void dispose() {
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}
