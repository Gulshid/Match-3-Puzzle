import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/level_definitions.dart';
import '../../../../shared/widgets/shake_widget.dart';
import '../../../levels/application/levels_provider.dart';
import '../../application/providers/board_provider.dart';
import '../../domain/models/level_config.dart';
import '../widgets/grid_widget.dart';
import '../widgets/level_result_overlay.dart';
import '../widgets/pause_overlay.dart';

/// Plays [level]. `gameProvider` is now a family keyed by [LevelConfig]
/// (Phase 7), so every level gets its own isolated game state and this
/// screen never needs to manually reset anything on entry.
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

    // Record stars/unlock the next level exactly once, right when the
    // status flips to won (ref.listen avoids doing this on every rebuild).
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
      appBar: AppBar(
        title: Text(level.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            tooltip: 'Pause',
            onPressed: status == GameStatus.playing
                ? () => ref.read(provider.notifier).pause()
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  _Hud(
                    score: score,
                    targetScore: level.targetScore,
                    movesRemaining: movesRemaining,
                  ),
                  SizedBox(height: 8.h),
                  if (comboCount > 1)
                    TweenAnimationBuilder<double>(
                      key: ValueKey(comboCount),
                      tween: Tween(begin: 1.4, end: 1.0),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 8.r),
                        child: Text(
                          'Combo x$comboCount!',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
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
    );
  }
}

/// Score / target / moves-remaining readout.
///
/// Deliberately simple — the level map and menus around it are the main
/// Phase 7 additions; this HUD just needs score/moves visible and
/// testable, same as Phase 5.
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
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _HudStat(label: 'Score', value: '$score / $targetScore'),
        _HudStat(
          label: 'Moves',
          value: '$movesRemaining',
          valueColor: movesRemaining <= 5 ? theme.colorScheme.error : null,
        ),
      ],
    );
  }
}

class _HudStat extends StatelessWidget {
  const _HudStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
