import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glossy_button.dart';
import '../../../../shared/widgets/pop_in.dart';

/// Full-screen pause overlay: frosted-glass backdrop blur behind a
/// glossy 3D pop-in card with Resume / Quit actions.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: Colors.black.withOpacity(0.45),
          child: Center(
            child: PopIn(
              child: GlassCard(
                radius: 26,
                opacity: 0.22,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 28.h),
                child: SizedBox(
                  width: 260.w,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.candyBlue, AppColors.candyPurple],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.candyPurple.withOpacity(0.5),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Icon(Icons.pause_rounded, size: 34.r, color: Colors.white),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        'Paused',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 22.h),
                      SizedBox(
                        width: double.infinity,
                        child: GlossyButton(
                          onPressed: onResume,
                          color: AppColors.candyMint,
                          child: Text('Resume',
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
                          onPressed: onQuit,
                          color: theme.colorScheme.surfaceContainerHighest,
                          baseColor: Colors.black.withOpacity(0.3),
                          child: Text('Quit to Levels',
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
        ),
      ),
    );
  }
}
