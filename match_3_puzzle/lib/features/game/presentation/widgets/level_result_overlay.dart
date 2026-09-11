import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/models/level_config.dart';

/// Full-screen overlay shown when a level is won or lost.
///
/// Phase 7: added a 0-3 star row and split the single "Retry" action
/// into level-map-aware actions (Retry / Next Level / Level Select),
/// since the game is no longer a single hardcoded level.
class LevelResultOverlay extends StatelessWidget {
  const LevelResultOverlay({
    super.key,
    required this.status,
    required this.score,
    required this.targetScore,
    required this.stars,
    required this.hasNextLevel,
    required this.onRetry,
    required this.onNextLevel,
    required this.onLevelSelect,
  });

  final GameStatus status;
  final int score;
  final int targetScore;
  final int stars;
  final bool hasNextLevel;
  final VoidCallback onRetry;
  final VoidCallback onNextLevel;
  final VoidCallback onLevelSelect;

  @override
  Widget build(BuildContext context) {
    final isWin = status == GameStatus.won;
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 32.w),
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 28.h),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWin ? Icons.emoji_events : Icons.replay_circle_filled,
                  size: 56.r,
                  color: isWin ? Colors.amber : theme.colorScheme.error,
                ),
                SizedBox(height: 12.h),
                Text(
                  isWin ? 'Level Complete!' : 'Out of Moves',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (isWin) ...[
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Icon(
                        Icons.star,
                        size: 30.r,
                        color: i < stars
                            ? Colors.amber
                            : theme.colorScheme.onSurface.withOpacity(0.2),
                      );
                    }),
                  ),
                ],
                SizedBox(height: 8.h),
                Text(
                  'Score: $score / $targetScore',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 24.h),
                if (isWin && hasNextLevel)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onNextLevel,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Text('Next Level',
                            style: TextStyle(fontSize: 16.sp)),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onRetry,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child:
                            Text('Retry', style: TextStyle(fontSize: 16.sp)),
                      ),
                    ),
                  ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onLevelSelect,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Text('Level Select',
                          style: TextStyle(fontSize: 16.sp)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
