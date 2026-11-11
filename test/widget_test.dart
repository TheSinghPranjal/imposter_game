import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/app/app.dart';
import 'package:imposter_game/app/studio_splash_screen.dart';
import 'package:imposter_game/app/theme/app_theme.dart';
import 'package:imposter_game/core/constants/game_constants.dart';

void main() {
  testWidgets('app boots to home after splash bootstrap override', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FindTheImposterApp()));

    expect(find.text('Imposter Game'), findsOneWidget);
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, StudioSplashScreen.bearAsset);

    await tester.pump(
      const Duration(milliseconds: GameConstants.splashDurationMs),
    );

    expect(find.text('The Lazy Bear Club'), findsNothing);
    expect(find.byType(FindTheImposterApp), findsOneWidget);
  });

  testWidgets(
    'splash byline stays readable in light and dark, phone and tablet',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> pumpAt(Size size, ThemeMode mode) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            home: const StudioSplashScreen(),
          ),
        );
        expect(find.text('Imposter Game'), findsOneWidget);
        expect(find.text('by'), findsOneWidget);
        expect(find.text('The Lazy Bear Club'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      }

      await pumpAt(const Size(320, 568), ThemeMode.light);
      await pumpAt(const Size(360, 640), ThemeMode.dark);
      await pumpAt(const Size(390, 844), ThemeMode.light);
      await pumpAt(const Size(800, 1280), ThemeMode.dark);
      await pumpAt(const Size(1024, 1366), ThemeMode.light);
      await pumpAt(const Size(667, 375), ThemeMode.dark);

      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpAt(const Size(320, 568), ThemeMode.light);
      await pumpAt(const Size(844, 390), ThemeMode.dark);
    },
  );
}
