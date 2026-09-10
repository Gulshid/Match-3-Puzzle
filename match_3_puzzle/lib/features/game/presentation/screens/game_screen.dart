import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../application/providers/board_provider.dart';
import '../widgets/grid_widget.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // .select() so this only rebuilds when comboCount itself changes,
    // not on every board update.
    final comboCount = ref.watch(gameProvider.select((s) => s.comboCount));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match-3 Puzzle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New board',
            onPressed: () => ref.read(gameProvider.notifier).newGame(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              // Temporary debug readout so Phase 4's cascade/combo logic
              // is visible before Phase 5 turns this into real scoring UI.
              if (comboCount > 1)
                Padding(
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
              const Expanded(child: GridWidget()),
            ],
          ),
        ),
      ),
    );
  }
}
