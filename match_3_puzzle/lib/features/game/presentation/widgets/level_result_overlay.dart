import 'dart:math';
import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glossy_button.dart';
import '../../../../shared/widgets/pop_in.dart';
import '../../domain/models/level_config.dart';

/// Full-screen overlay shown when a level is won or lost — frosted
/// glass backdrop, a 3D pop-in card, staggered star reveal, and a
/// confetti burst on a win.
class LevelResultOverlay extends StatefulWidget {
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
  State<LevelResultOverlay> createState() => _LevelResultOverlayState();
}

class _LevelResultOverlayState extends State<LevelResultOverlay> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    if (widget.status == GameStatus.won) {
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWin = widget.status == GameStatus.won;
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          if (isWin)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 24,
                maxBlastForce: 22,
                minBlastForce: 8,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  AppColors.candyPink,
                  AppColors.candyBlue,
                  AppColors.candyMint,
                  AppColors.candyYellow,
                  AppColors.candyOrange,
                ],
              ),
            ),
          Center(
            child: PopIn(
              child: GlassCard(
                radius: 28,
                opacity: 0.22,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 28.h),
                child: SizedBox(
                  width: 280.w,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isWin
                                ? [AppColors.gold, AppColors.candyOrange]
                                : [Colors.grey.shade600, Colors.grey.shade800],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isWin ? AppColors.gold : Colors.black)
                                  .withOpacity(0.5),
                              blurRadius: 22,
                            ),
                          ],
                        ),
                        child: Icon(
                          isWin ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                          size: 40.r,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        isWin ? 'Level Complete!' : 'Out of Moves',
                        style: TextStyle(
                          fontSize: 23.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isWin) ...[
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            return _StaggeredStar(
                              filled: i < widget.stars,
                              delay: Duration(milliseconds: 120 * i),
                            );
                          }),
                        ),
                      ],
                      SizedBox(height: 10.h),
                      Text(
                        'Score: ${widget.score} / ${widget.targetScore}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.75),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      if (isWin && widget.hasNextLevel)
                        SizedBox(
                          width: double.infinity,
                          child: GlossyButton(
                            onPressed: widget.onNextLevel,
                            color: AppColors.candyMint,
                            child: Text('Next Level',
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: GlossyButton(
                            onPressed: widget.onRetry,
                            color: AppColors.candyPink,
                            child: Text('Retry',
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        width: double.infinity,
                        child: GlossyButton(
                          onPressed: widget.onLevelSelect,
                          color: theme.colorScheme.surfaceContainerHighest,
                          baseColor: Colors.black.withOpacity(0.3),
                          child: Text('Level Select',
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single result star that pops in with a delay + spin, for a
/// cascading reveal across the 3 stars instead of appearing at once.
class _StaggeredStar extends StatelessWidget {
  const _StaggeredStar({required this.filled, required this.delay});

  final bool filled;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: PopIn(
        delay: delay,
        child: Icon(
          Icons.star_rounded,
          size: 36.r,
          color: filled
              ? AppColors.gold
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          shadows: filled
              ? [Shadow(color: AppColors.gold.withOpacity(0.6), blurRadius: 12)]
              : null,
        ),
      ),
    );
  }
}
