import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/pop_in.dart';
import '../../application/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final tiles = [
      (
        icon: Icons.volume_up_rounded,
        color: AppColors.candyOrange,
        title: 'Sound effects',
        subtitle: 'Swap, match, and combo sounds',
        value: settings.soundEnabled,
        onChanged: notifier.toggleSound,
      ),
      (
        icon: Icons.music_note_rounded,
        color: AppColors.candyPurple,
        title: 'Music',
        subtitle: 'Background music',
        value: settings.musicEnabled,
        onChanged: notifier.toggleMusic,
      ),
      (
        icon: Icons.vibration_rounded,
        color: AppColors.candyMint,
        title: 'Vibration',
        subtitle: 'Haptic feedback on moves',
        value: settings.vibrationEnabled,
        onChanged: notifier.toggleVibration,
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, kToolbarHeight + 16.h, 16.w, 16.h),
            itemCount: tiles.length,
            separatorBuilder: (_, __) => SizedBox(height: 14.h),
            itemBuilder: (context, index) {
              final t = tiles[index];
              return PopIn(
                delay: Duration(milliseconds: 70 * index),
                child: GlassCard(
                  radius: 20,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: t.color.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(t.icon, color: t.color, size: 22.r),
                    ),
                    title: Text(t.title,
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    subtitle: Text(t.subtitle,
                        style: TextStyle(
                            fontSize: 12.sp, color: Colors.white.withOpacity(0.7))),
                    value: t.value,
                    onChanged: t.onChanged,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
