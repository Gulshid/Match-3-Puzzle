import 'package:go_router/go_router.dart';

import '../core/constants/level_definitions.dart';
import '../features/game/presentation/screens/game_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/levels/presentation/screens/level_select_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/levels',
          builder: (context, state) => const LevelSelectScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/game/:levelId',
          builder: (context, state) {
            final levelId =
                int.tryParse(state.pathParameters['levelId'] ?? '') ?? 1;
            return GameScreen(level: LevelDefinitions.byId(levelId));
          },
        ),
      ],
    );
  }
}
