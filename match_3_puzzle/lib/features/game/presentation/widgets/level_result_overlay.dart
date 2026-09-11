import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/models/level_config.dart';

/// Full-screen overlay shown when a level is won or lost.
///
/// Intentionally plain (no confetti/stars/animation) — Phase 7 builds
/// the real result screen with star ratings and a proper level-map
/// "next level" flow. This just needs to make win/lose visible and
/// offer a retry.
class LevelResultOverlay extends StatelessWidget {
  const LevelResultOverlay({
    super.key,
    required this.status,
    required this.score,
    required this.targetScore,
    required this.onRetry,
  });

  final GameStatus status;
  final int score;
  final int targetScore;
  final VoidCallback onRetry;

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
                SizedBox(height: 8.h),
                Text(
                  'Score: $score / $targetScore',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onRetry,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Text(
                        'Retry',
                        style: TextStyle(fontSize: 16.sp),
                      ),
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
