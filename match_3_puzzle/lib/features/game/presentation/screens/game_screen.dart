import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/level_definitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/shake_widget.dart';
import '../../../levels/application/levels_provider.dart';
import '../../application/providers/board_provider.dart';
import '../../domain/models/level_config.dart';
import '../widgets/grid_widget.dart';
import '../widgets/level_result_overlay.dart';
import '../widgets/pause_overlay.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key, required this.level});

  final LevelConfig level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = gameProvider(level);

    final score = ref.watch(provider.select((s) => s.score));
    final movesRemaining = ref.watch(provider.select((s) => s.movesRemaining));
    final comboCount = ref.watch(provider.select((s) => s.comboCount));
    final shakeTrigger = ref.watch(provider.select((s) => s.shakeTrigger));
    final status = ref.watch(provider.select((s) => s.status));
    final isPaused = ref.watch(provider.select((s) => s.isPaused));

    ref.listen(provider.select((s) => s.status), (previous, next) {
      if (next == GameStatus.won && previous != GameStatus.won) {
        ref
            .read(levelsProvider.notifier)
            .recordResult(level.id, ref.read(provider).score, level.targetScore);
      }
    });

    final nextLevelMatches =
        LevelDefinitions.all.where((l) => l.id == level.id + 1);
    final nextLevel =
        nextLevelMatches.isEmpty ? null : nextLevelMatches.first;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(level.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause_rounded),
            tooltip: 'Pause',
            onPressed: status == GameStatus.playing
                ? () => ref.read(provider.notifier).pause()
                : null,
          ),
        ],
      ),
      body: AnimatedGradientBackground(
        extraVibrant: true,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, kToolbarHeight + 8.h, 16.w, 16.h),
                child: Column(
                  children: [
                    _Hud(
                      score: score,
                      targetScore: level.targetScore,
                      movesRemaining: movesRemaining,
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 34.h,
                      child: Center(
                        child: comboCount > 1
                            ? TweenAnimationBuilder<double>(
                                key: ValueKey(comboCount),
                                tween: Tween(begin: 1.5, end: 1.0),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.elasticOut,
                                builder: (context, scale, child) =>
                                    Transform.scale(scale: scale, child: child),
                                child: _ComboBadge(comboCount: comboCount),
                              )
                            : null,
                      ),
                    ),
                    Expanded(
                      child: ShakeWidget(
                        trigger: shakeTrigger,
                        child: GridWidget(level: level),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPaused)
                PauseOverlay(
                  onResume: () => ref.read(provider.notifier).resume(),
                  onQuit: () => context.go('/levels'),
                ),
              if (status != GameStatus.playing)
                LevelResultOverlay(
                  status: status,
                  score: score,
                  targetScore: level.targetScore,
                  stars: ref
                      .watch(levelsProvider)
                      .firstWhere((p) => p.levelId == level.id)
                      .stars,
                  hasNextLevel: nextLevel != null &&
                      ref
                          .watch(levelsProvider)
                          .firstWhere((p) => p.levelId == nextLevel.id)
                          .isUnlocked,
                  onRetry: () => ref.read(provider.notifier).newGame(),
                  onNextLevel: nextLevel == null
                      ? () {}
                      : () => context.pushReplacement('/game/${nextLevel.id}'),
                  onLevelSelect: () => context.go('/levels'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.comboCount});
  final int comboCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.candyOrange, AppColors.candyPink],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.candyPink.withOpacity(0.55),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        'COMBO x$comboCount!',
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Score / target / moves-remaining readout, styled as two glass chips.
class _Hud extends StatelessWidget {
  const _Hud({
    required this.score,
    required this.targetScore,
    required this.movesRemaining,
  });

  final int score;
  final int targetScore;
  final int movesRemaining;

  @override
  Widget build(BuildContext context) {
    final lowMoves = movesRemaining <= 5;
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            radius: 18,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: _HudStat(
              icon: Icons.stars_rounded,
              iconColor: AppColors.gold,
              label: 'Score',
              value: '$score / $targetScore',
            ),
          ),
        ),
        SizedBox(width: 10.w),
        GlassCard(
          radius: 18,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: _HudStat(
            icon: Icons.bolt_rounded,
            iconColor: lowMoves ? AppColors.emberRed : AppColors.candyBlue,
            label: 'Moves',
            value: '$movesRemaining',
            valueColor: lowMoves ? AppColors.emberRed : null,
          ),
        ),
      ],
    );
  }
}

class _HudStat extends StatelessWidget {
  const _HudStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22.r),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: onSurface.withOpacity(0.65)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: valueColor ?? onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
