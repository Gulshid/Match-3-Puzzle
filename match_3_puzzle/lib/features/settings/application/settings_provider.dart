import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';

/// User-facing toggles. In-memory only for now — Phase 10 persists
/// these via shared_preferences alongside level progress; the shape
/// here is deliberately simple so that becomes a small addition, not a
/// rewrite.
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
  SettingsNotifier(this._ref) : super(const SettingsState());

  final Ref _ref;

  void toggleSound(bool value) {
    state = state.copyWith(soundEnabled: value);
    _ref.read(audioServiceProvider).setSoundEnabled(value);
  }

  void toggleMusic(bool value) {
    state = state.copyWith(musicEnabled: value);
    _ref.read(audioServiceProvider).setMusicEnabled(value);
  }

  void toggleVibration(bool value) {
    state = state.copyWith(vibrationEnabled: value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref),
);
