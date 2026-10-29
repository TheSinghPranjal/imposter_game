import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/core/constants/ad_ids.dart';
import 'package:imposter_game/features/imposter/domain/enums/game_phase.dart';

void main() {
  test('rejects Google sample IDs and placeholders', () {
    expect(
      AdIds.isValidProductionId(AdIds.sampleAndroidAppId, appId: true),
      isFalse,
    );
    expect(
      AdIds.isValidProductionId(AdIds.androidBannerTestId, appId: false),
      isFalse,
    );
    expect(
      AdIds.isValidProductionId('TODO_ADMOB_ANDROID_APP_ID', appId: true),
      isFalse,
    );
    expect(AdIds.isValidProductionId('', appId: false), isFalse);
    expect(
      AdIds.isValidProductionId(
        'ca-app-pub-0000000000000000/1234567890',
        appId: false,
      ),
      isFalse,
    );
  });

  test('accepts this publisher app and unit IDs', () {
    expect(
      AdIds.isValidProductionId(
        'ca-app-pub-8661918790125012~8544493942',
        appId: true,
      ),
      isTrue,
    );
    expect(
      AdIds.isValidProductionId(
        'ca-app-pub-8661918790125012/2909023888',
        appId: false,
      ),
      isTrue,
    );
    expect(
      AdIds.isValidProductionId(
        'ca-app-pub-8661918790125012/2909023888',
        appId: true,
      ),
      isFalse,
    );
    expect(
      AdIds.isValidProductionId(
        'ca-app-pub-8661918790125012~8544493942',
        appId: false,
      ),
      isFalse,
    );
  });

  test('config file values are real IDs or TODO placeholders', () {
    final decoded =
        jsonDecode(File('config/admob.json').readAsStringSync()) as Map;
    final ids = decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );

    expect(ids.keys.toSet(), {...AdIds.androidKeys, ...AdIds.iosKeys});

    for (final entry in ids.entries) {
      final value = entry.value.trim();
      final valid = AdIds.isValidProductionId(
        value,
        appId: AdIds.isAppIdKey(entry.key),
      );
      expect(
        valid || value.startsWith('TODO_'),
        isTrue,
        reason: '${entry.key}=$value',
      );
    }
  });

  test('iOS xcconfig matches the JSON app ID', () {
    final decoded =
        jsonDecode(File('config/admob.json').readAsStringSync()) as Map;
    final expected = decoded[AdIds.iosAppIdKey].toString().trim();
    final xcconfig = File('ios/Flutter/AdMob.xcconfig').readAsStringSync();
    expect(xcconfig.contains('GAD_APPLICATION_IDENTIFIER=$expected'), isTrue);
  });

  test('banners stay off the secret pass-the-phone reveal flow', () {
    for (final phase in GamePhase.values) {
      if (phase.isRevealFlow) {
        expect(phase.showsBanner, isFalse, reason: phase.name);
      }
    }
    expect(GamePhase.home.showsBanner, isTrue);
    expect(GamePhase.roundReady.showsBanner, isTrue);
    expect(GamePhase.allRevealed.showsBanner, isFalse);
    expect(GamePhase.playerSetup.showsBanner, isFalse);
    expect(GamePhase.configuration.showsBanner, isFalse);
  });
}
