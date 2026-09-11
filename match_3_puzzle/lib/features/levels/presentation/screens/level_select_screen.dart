import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/level_definitions.dart';
import '../../application/levels_provider.dart';

class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressList = ref.watch(levelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Level')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth < 600 ? 3 : 5;

          return GridView.builder(
            padding: EdgeInsets.all(16.r),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1,
            ),
            itemCount: LevelDefinitions.all.length,
            itemBuilder: (context, index) {
              final level = LevelDefinitions.all[index];
              final progress = progressList.firstWhere(
                (p) => p.levelId == level.id,
              );

              return _LevelTile(
                title: level.title,
                stars: progress.stars,
                isUnlocked: progress.isUnlocked,
                onTap: progress.isUnlocked
                    ? () => context.push('/game/${level.id}')
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.title,
    required this.stars,
    required this.isUnlocked,
    required this.onTap,
  });

  final String title;
  final int stars;
  final bool isUnlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isUnlocked
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.all(8.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isUnlocked)
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              else
                Icon(
                  Icons.lock,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 22.r,
                ),
              if (isUnlocked) ...[
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Icon(
                      Icons.star,
                      size: 14.r,
                      color: i < stars
                          ? Colors.amber
                          : theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.25),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
