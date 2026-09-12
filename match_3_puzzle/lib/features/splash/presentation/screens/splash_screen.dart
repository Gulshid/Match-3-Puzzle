import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';

/// The app's launch screen.
///
/// Two animation layers run in parallel:
/// - [_spinController] loops forever: the logo's 3D Y-axis spin and the
///   orbiting-dot ring around it. Purely decorative "alive" motion.
/// - [_revealController] runs once, top to bottom of the widget tree,
///   staggering the logo scale-in, title/tagline fade-slide, and the
///   loading bar fill via [Interval]s on one timeline. When it
///   completes, the screen fades out and hands off to Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _revealController,
    curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
  );

  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _revealController,
    curve: const Interval(0.28, 0.55, curve: Curves.easeOut),
  );

  late final Animation<Offset> _titleSlide = Tween(
    begin: const Offset(0, 0.25),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _revealController,
    curve: const Interval(0.28, 0.55, curve: Curves.easeOut),
  ));

  late final Animation<double> _barFade = CurvedAnimation(
    parent: _revealController,
    curve: const Interval(0.45, 0.6, curve: Curves.easeOut),
  );

  late final Animation<double> _barFill = CurvedAnimation(
    parent: _revealController,
    curve: const Interval(0.45, 1.0, curve: Curves.easeInOutCubic),
  );

  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goHome();
    });
  }

  Future<void> _goHome() async {
    if (_leaving || !mounted) return;
    setState(() => _leaving = true);
    await Future.delayed(const Duration(milliseconds: 320));
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _spinController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        extraVibrant: true,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 320),
          opacity: _leaving ? 0.0 : 1.0,
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _OrbitingLogo(
                  spinController: _spinController,
                  scaleAnimation: _logoScale,
                ),
                SizedBox(height: 26.h),
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Column(
                      children: [
                        Text(
                          'Match-3 Puzzle',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'SWAP · MATCH · CASCADE',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.2,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _barFade,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 56.w),
                    child: _LoadingBar(progress: _barFill),
                  ),
                ),
                SizedBox(height: 14.h),
                FadeTransition(
                  opacity: _barFade,
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(height: 36.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The centrepiece: a glossy 3D-spinning diamond logo with a ring of
/// small orbiting dots circling it at a different speed/plane, giving
/// a layered, "premium loading" feel rather than a static image.
class _OrbitingLogo extends StatelessWidget {
  const _OrbitingLogo({
    required this.spinController,
    required this.scaleAnimation,
  });

  final AnimationController spinController;
  final Animation<double> scaleAnimation;

  @override
  Widget build(BuildContext context) {
    final size = 150.r;

    return ScaleTransition(
      scale: scaleAnimation,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: spinController,
          builder: (context, _) {
            final t = spinController.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Orbiting dots — a slower counter-rotating ring.
                Transform.rotate(
                  angle: -t * 2 * pi,
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _OrbitPainter(),
                  ),
                ),
                // Soft outer glow pulse.
                Container(
                  width: size * 0.66,
                  height: size * 0.66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.candyOrange
                            .withOpacity(0.35 + 0.2 * sin(t * 2 * pi)),
                        blurRadius: 46,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
                // The logo itself, true 3D Y-axis spin.
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0016)
                    ..rotateY(t * 2 * pi),
                  child: Container(
                    width: size * 0.58,
                    height: size * 0.58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 0.16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.candyYellow, AppColors.candyOrange],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: size * 0.3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  static const _dotColors = [
    AppColors.candyPink,
    AppColors.candyBlue,
    AppColors.candyMint,
    AppColors.candyPurple,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    for (var i = 0; i < _dotColors.length; i++) {
      final angle = (2 * pi / _dotColors.length) * i;
      final pos = center + Offset(cos(angle), sin(angle)) * radius;
      final paint = Paint()..color = _dotColors[i];
      canvas.drawCircle(pos, size.shortestSide * 0.035, paint);
    }

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) => false;
}

/// Glass-track loading bar with a glossy gradient fill and a shimmer
/// highlight, filled in step with [progress].
class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 10.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.value.clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.candyPink, AppColors.candyOrange],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
