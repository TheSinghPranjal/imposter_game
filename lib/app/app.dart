import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/imposter/domain/enums/app_theme_mode.dart';
import '../features/imposter/presentation/providers/game_controller.dart';
import '../features/imposter/presentation/screens/game_flow_screen.dart';
import 'theme/app_theme.dart';

class FindTheImposterApp extends ConsumerWidget {
  const FindTheImposterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      gameControllerProvider.select((s) => s.settings.themeMode),
    );
    return MaterialApp(
      title: 'Imposter Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      home: const GameFlowScreen(),
    );
  }
}
