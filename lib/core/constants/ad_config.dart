import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ad_ids.dart';

/// Ad unit selection for Find the Imposter.
///
/// Production IDs live in `config/admob.json` (bundled as an asset) and can be
/// overridden at compile time with `--dart-define` / `--dart-define-from-file`
/// using the same keys. Debug and profile builds ignore them and use Google's
/// sample units. Release builds throw if the IDs for the current platform are
/// still sample values or placeholders.
class AdConfig {
  AdConfig._();

  static const String _envAndroidAppId = String.fromEnvironment(
    AdIds.androidAppIdKey,
  );
  static const String _envIosAppId = String.fromEnvironment(AdIds.iosAppIdKey);
  static const String _envAndroidBanner = String.fromEnvironment(
    AdIds.androidBannerKey,
  );
  static const String _envIosBanner = String.fromEnvironment(
    AdIds.iosBannerKey,
  );
  static const String _envAndroidInterstitial = String.fromEnvironment(
    AdIds.androidInterstitialKey,
  );
  static const String _envIosInterstitial = String.fromEnvironment(
    AdIds.iosInterstitialKey,
  );

  static Map<String, String> _ids = const {};
  static bool _loaded = false;
  static bool _canRequestAds = false;
  static final List<VoidCallback> _canRequestAdsListeners = [];

  /// False only when consent is required and was not granted, or the user
  /// denied ads. A failed or timed-out UMP check leaves this true so ad
  /// requests are still made outside regions that require consent.
  static bool get canRequestAds => _canRequestAds;

  static set canRequestAds(bool value) {
    if (_canRequestAds == value) return;
    _canRequestAds = value;
    for (final listener in List<VoidCallback>.of(_canRequestAdsListeners)) {
      listener();
    }
  }

  static void addCanRequestAdsListener(VoidCallback listener) {
    _canRequestAdsListeners.add(listener);
  }

  static void removeCanRequestAdsListener(VoidCallback listener) {
    _canRequestAdsListeners.remove(listener);
  }

  /// Sample units in debug and profile. Real units only in release.
  static bool get isTestMode => !kReleaseMode;

  static bool get adsSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> load() async {
    final fromFile = await _readAsset();
    _ids = _applyEnvironmentOverrides(fromFile);
    _loaded = true;

    if (kReleaseMode && adsSupported) {
      final problems = productionIdProblems(
        ios: defaultTargetPlatform == TargetPlatform.iOS,
      );
      if (problems.isNotEmpty) {
        final message = StringBuffer()
          ..writeln(
            'Release build is still using sample or placeholder AdMob IDs.',
          )
          ..writeln(
            'This app would keep serving Google test ads. Fix config/admob.json',
          )
          ..writeln(
            '(publisher ${AdIds.publisherPrefix}) and rebuild. See README:',
          )
          ..writeln('Configuring AdMob for release.');
        for (final problem in problems) {
          message.writeln('- $problem');
        }
        debugPrint(message.toString());
        throw StateError(message.toString());
      }
    }

    debugPrint(
      'AdMob mode: ${isTestMode ? 'TEST (Google sample units)' : 'RELEASE (production units)'} '
      'banner=$bannerAdUnitId '
      'interstitial=$interstitialAdUnitId',
    );
  }

  static List<String> productionIdProblems({required bool ios}) {
    return AdIds.problemsFor(_ids, ios: ios);
  }

  static String get bannerAdUnitId => _select(
    testIos: AdIds.iosBannerTestId,
    testAndroid: AdIds.androidBannerTestId,
    prodIos: AdIds.iosBannerKey,
    prodAndroid: AdIds.androidBannerKey,
  );

  static String get interstitialAdUnitId => _select(
    testIos: AdIds.iosInterstitialTestId,
    testAndroid: AdIds.androidInterstitialTestId,
    prodIos: AdIds.iosInterstitialKey,
    prodAndroid: AdIds.androidInterstitialKey,
  );

  static String _select({
    required String testIos,
    required String testAndroid,
    required String prodIos,
    required String prodAndroid,
  }) {
    if (isTestMode) {
      return _ios ? testIos : testAndroid;
    }
    if (!_loaded) {
      throw StateError(
        'AdConfig.load() must run before reading production ad unit IDs.',
      );
    }
    return _ids[_ios ? prodIos : prodAndroid]?.trim() ?? '';
  }

  static Future<Map<String, String>> _readAsset() async {
    try {
      final raw = await rootBundle.loadString('config/admob.json');
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw FormatException('config/admob.json must be a JSON object');
      }
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString().trim()),
      );
    } catch (error) {
      if (kReleaseMode) {
        throw StateError(
          'Release build could not read config/admob.json: $error',
        );
      }
      debugPrint(
        'AdMob config asset unavailable ($error). '
        'Test mode will use Google sample ad units.',
      );
      return const {};
    }
  }

  static Map<String, String> _applyEnvironmentOverrides(
    Map<String, String> fromFile,
  ) {
    final merged = Map<String, String>.from(fromFile);
    void override(String key, String value) {
      if (value.isNotEmpty) merged[key] = value.trim();
    }

    override(AdIds.androidAppIdKey, _envAndroidAppId);
    override(AdIds.iosAppIdKey, _envIosAppId);
    override(AdIds.androidBannerKey, _envAndroidBanner);
    override(AdIds.iosBannerKey, _envIosBanner);
    override(AdIds.androidInterstitialKey, _envAndroidInterstitial);
    override(AdIds.iosInterstitialKey, _envIosInterstitial);
    return merged;
  }
}
