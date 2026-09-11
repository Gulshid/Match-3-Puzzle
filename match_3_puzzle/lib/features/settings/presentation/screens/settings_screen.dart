import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../application/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        children: [
          SwitchListTile(
            title: const Text('Sound effects'),
            subtitle: const Text('Swap, match, and combo sounds'),
            value: settings.soundEnabled,
            onChanged: notifier.toggleSound,
          ),
          SwitchListTile(
            title: const Text('Music'),
            subtitle: const Text('Background music'),
            value: settings.musicEnabled,
            onChanged: notifier.toggleMusic,
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Haptic feedback on moves'),
            value: settings.vibrationEnabled,
            onChanged: notifier.toggleVibration,
          ),
        ],
      ),
    );
  }
}
