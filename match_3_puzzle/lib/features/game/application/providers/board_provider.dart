import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:match3_puzzle/core/constants/design_constants.dart';
import 'package:match3_puzzle/features/game/domain/models/board_model.dart';

/// Holds and mutates the current [BoardModel].
///
/// Phase 2 only needs `newGame()`. Swap/match/cascade methods land in
/// Phase 3 and 4 on this same notifier, so the widget layer never has to
/// change how it talks to the board.
class BoardNotifier extends StateNotifier<BoardModel> {
  BoardNotifier()
      : super(
          BoardModel.generateRandom(
            rows: BoardConfig.rows,
            cols: BoardConfig.cols,
          ),
        );

  void newGame() {
    state = BoardModel.generateRandom(
      rows: BoardConfig.rows,
      cols: BoardConfig.cols,
    );
  }
}

final boardProvider = StateNotifierProvider<BoardNotifier, BoardModel>(
  (ref) => BoardNotifier(),
);
