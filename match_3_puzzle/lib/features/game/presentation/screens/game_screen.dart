import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/shake_widget.dart';
import '../../application/providers/board_provider.dart';
import '../../domain/models/level_config.dart';
import '../widgets/grid_widget.dart';
import '../widgets/level_result_overlay.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(gameProvider.select((s) => s.score));
    final movesRemaining =
        ref.watch(gameProvider.select((s) => s.movesRemaining));
    final targetScore =
        ref.watch(gameProvider.select((s) => s.level.targetScore));
    final comboCount = ref.watch(gameProvider.select((s) => s.comboCount));
    final shakeTrigger =
        ref.watch(gameProvider.select((s) => s.shakeTrigger));
    final status = ref.watch(gameProvider.select((s) => s.status));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match-3 Puzzle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New game',
            onPressed: () => ref.read(gameProvider.notifier).newGame(),
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
                    targetScore: targetScore,
                    movesRemaining: movesRemaining,
                  ),
                  SizedBox(height: 8.h),
                  // Phase 6: pop the combo readout each time comboCount
                  // changes, using the ValueKey to restart the tween.
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
                      child: const GridWidget(),
                    ),
                  ),
                ],
              ),
            ),
            if (status != GameStatus.playing)
              LevelResultOverlay(
                status: status,
                score: score,
                targetScore: targetScore,
                onRetry: () => ref.read(gameProvider.notifier).newGame(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Score / target / moves-remaining readout.
///
/// Deliberately simple — Phase 7 replaces this with the real HUD
/// (pause button, objective icons, etc) as part of the full menu/level
/// flow. This just needs to make Phase 5's scoring and move limit
/// visible and testable.
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
            color: theme.colorScheme.onSurface.withOpacity(0.6),
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
