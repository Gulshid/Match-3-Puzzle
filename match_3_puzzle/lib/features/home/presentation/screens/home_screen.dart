import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/glossy_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _Logo3D(controller: _controller),
                SizedBox(height: 18.h),
                Text(
                  'Match-3 Puzzle',
                  style: TextStyle(
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 12),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Swap, match, and cascade your way to victory',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: GlossyButton(
                    height: 60.h,
                    onPressed: () => context.push('/levels'),
                    color: AppColors.candyPink,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26.r),
                        SizedBox(width: 6.w),
                        Text('Play',
                            style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  child: GlossyButton(
                    height: 54.h,
                    onPressed: () => context.push('/settings'),
                    color: AppColors.candyBlue,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.settings_rounded, color: Colors.white, size: 22.r),
                        SizedBox(width: 6.w),
                        Text('Settings',
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The home-screen emblem: a glossy diamond that continuously rotates
/// in true 3D (perspective Y-axis spin) with a soft floating bob and a
/// glow that pulses in sync.
class _Logo3D extends StatelessWidget {
  const _Logo3D({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final spin = t * 2 * pi;
        final bob = sin(t * 2 * pi) * 6;
        final glow = 0.5 + 0.3 * sin(t * 2 * pi);

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(spin),
            child: Container(
              width: 96.r,
              height: 96.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.candyYellow, AppColors.candyOrange],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.candyOrange.withOpacity(glow),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.grid_view_rounded, size: 52.r, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
