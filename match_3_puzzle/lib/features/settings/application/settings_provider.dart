import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/audio/audio_providers.dart';
import '../../levels/application/levels_provider.dart';

const _kSoundKey = 'settings_sound_v1';
const _kMusicKey = 'settings_music_v1';
const _kVibrationKey = 'settings_vibration_v1';

/// User-facing toggles, now persisted via [SharedPreferences].
///
/// Phase 10 changes: constructor reads saved values; every toggle
/// immediately persists. The [sharedPreferencesProvider] is the same
/// one used by [LevelsNotifier] — one prefs instance shared app-wide.
class SettingsState {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;

  const SettingsState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._ref, this._prefs)
      : super(SettingsState(
          soundEnabled: _prefs.getBool(_kSoundKey) ?? true,
          musicEnabled: _prefs.getBool(_kMusicKey) ?? true,
          vibrationEnabled: _prefs.getBool(_kVibrationKey) ?? true,
        ));

  final Ref _ref;
  final SharedPreferences _prefs;

  void toggleSound(bool value) {
    state = state.copyWith(soundEnabled: value);
    _prefs.setBool(_kSoundKey, value);
    _ref.read(audioServiceProvider).setSoundEnabled(value);
  }

  void toggleMusic(bool value) {
    state = state.copyWith(musicEnabled: value);
    _prefs.setBool(_kMusicKey, value);
    _ref.read(audioServiceProvider).setMusicEnabled(value);
  }

  void toggleVibration(bool value) {
    state = state.copyWith(vibrationEnabled: value);
    _prefs.setBool(_kVibrationKey, value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref, ref.watch(sharedPreferencesProvider)),
);
