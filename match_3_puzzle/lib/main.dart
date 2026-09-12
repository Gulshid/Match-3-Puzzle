import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/audio/audio_providers.dart';
import 'core/constants/design_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/levels/application/levels_provider.dart';
import 'features/settings/application/settings_provider.dart';
import 'routes/app_router.dart';

/// Phase 10: [SharedPreferences] must be initialised before [runApp]
/// so the [ProviderScope] override is available synchronously.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Provide the singleton prefs instance to all providers that need it.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const Match3App(),
    ),
  );
}

class Match3App extends StatelessWidget {
  const Match3App({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScreenUtilInit(
          designSize: DesignConstants.designSizeFor(constraints.maxWidth),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, _) => const _AppEntry(),
        );
      },
    );
  }
}

class _AppEntry extends ConsumerStatefulWidget {
  const _AppEntry();

  @override
  ConsumerState<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<_AppEntry> {
  late final _router = AppRouter.create();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      if (settings.musicEnabled) {
        ref
            .read(audioServiceProvider)
            .playMusic('sounds/bg_music.mp3', volume: 0.35);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Match-3 Puzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      builder: (ctx, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
        );
        return child!;
      },
    );
  }
}
