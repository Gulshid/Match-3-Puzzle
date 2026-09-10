import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:match3_puzzle/features/game/application/providers/board_provider.dart';
import 'package:match3_puzzle/features/game/presentation/widgets/grid_widget.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match-3 Puzzle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New board (Phase 2 test)',
            onPressed: () => ref.read(boardProvider.notifier).newGame(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: const GridWidget(),
        ),
      ),
    );
  }
}
