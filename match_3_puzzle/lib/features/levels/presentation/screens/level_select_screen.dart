import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/level_definitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/pop_in.dart';
import '../../application/levels_provider.dart';

class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressList = ref.watch(levelsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Select Level')),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 600 ? 3 : 5;

              return GridView.builder(
                padding: EdgeInsets.fromLTRB(16.r, kToolbarHeight + 16.r, 16.r, 16.r),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14.w,
                  mainAxisSpacing: 14.h,
                  childAspectRatio: 1,
                ),
                itemCount: LevelDefinitions.all.length,
                itemBuilder: (context, index) {
                  final level = LevelDefinitions.all[index];
                  final progress = progressList.firstWhere(
                    (p) => p.levelId == level.id,
                  );

                  return PopIn(
                    delay: Duration(milliseconds: 60 * index),
                    child: _LevelNode(
                      number: level.id,
                      stars: progress.stars,
                      isUnlocked: progress.isUnlocked,
                      onTap: progress.isUnlocked
                          ? () => context.push('/game/${level.id}')
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

const _nodeGradients = [
  [AppColors.candyPink, Color(0xFFB6408C)],
  [AppColors.candyBlue, Color(0xFF2E6FBF)],
  [AppColors.candyMint, Color(0xFF1FA681)],
  [AppColors.candyOrange, Color(0xFFB85E1E)],
  [AppColors.candyPurple, Color(0xFF5B3AA8)],
];

/// A glossy, beveled 3D level node — press-in depth animation plus a
/// diagonal gloss highlight so the whole level map reads as a tray of
/// physical candy buttons rather than flat grid cells.
class _LevelNode extends StatefulWidget {
  const _LevelNode({
    required this.number,
    required this.stars,
    required this.isUnlocked,
    required this.onTap,
  });

  final int number;
  final int stars;
  final bool isUnlocked;
  final VoidCallback? onTap;

  @override
  State<_LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<_LevelNode> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = _nodeGradients[(widget.number - 1) % _nodeGradients.length];
    final enabled = widget.isUnlocked;
    final top = enabled ? colors[0] : Colors.grey.shade500;
    final bottom = enabled ? colors[1] : Colors.grey.shade700;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: EdgeInsets.only(top: _pressed ? 5 : 0, bottom: _pressed ? 0 : 5),
        decoration: BoxDecoration(
          color: Color.lerp(bottom, Colors.black, 0.25),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(top, Colors.white, 0.15)!, top, bottom],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 6.r,
                left: 10.r,
                right: 10.r,
                child: Container(
                  height: 8.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (enabled)
                    Text(
                      '${widget.number}',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 3),
                        ],
                      ),
                    )
                  else
                    Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.9), size: 22.r),
                  if (enabled) ...[
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Icon(
                          Icons.star_rounded,
                          size: 13.r,
                          color: i < widget.stars
                              ? AppColors.gold
                              : Colors.white.withOpacity(0.3),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
