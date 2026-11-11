import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/game_constants.dart';
import '../features/imposter/domain/enums/app_theme_mode.dart';
import '../features/imposter/presentation/providers/game_controller.dart';
import '../features/imposter/presentation/screens/game_flow_screen.dart';
import 'studio_splash_screen.dart';
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
      home: const _SplashGate(),
    );
  }
}

/// Branded splash, then the party flow. Bootstrap has already finished, so
/// the next screen is whatever phase the session is in (normally home).
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  Timer? _timer;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(milliseconds: GameConstants.splashDurationMs),
      () {
        if (mounted) setState(() => _finished = true);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return const GameFlowScreen();
    return const StudioSplashScreen();
  }
}
