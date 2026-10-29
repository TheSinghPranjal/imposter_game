/// Production AdMob ID rules for this app's publisher account.
///
/// Debug and profile builds never use these IDs. Release builds must, and
/// they must belong to publisher `pub-8661918790125012`.
class AdIds {
  AdIds._();

  static const String publisherId = 'pub-8661918790125012';
  static const String publisherPrefix = 'ca-app-pub-8661918790125012';

  /// Google's official sample publisher. Shipping these serves test ads.
  static const String samplePublisherFragment = 'ca-app-pub-3940256099942544';

  static const String androidAppIdKey = 'ADMOB_ANDROID_APP_ID';
  static const String iosAppIdKey = 'ADMOB_IOS_APP_ID';
  static const String androidBannerKey = 'ADMOB_ANDROID_BANNER_ID';
  static const String iosBannerKey = 'ADMOB_IOS_BANNER_ID';
  static const String androidInterstitialKey = 'ADMOB_ANDROID_INTERSTITIAL_ID';
  static const String iosInterstitialKey = 'ADMOB_IOS_INTERSTITIAL_ID';

  static const List<String> androidKeys = [
    androidAppIdKey,
    androidBannerKey,
    androidInterstitialKey,
  ];

  static const List<String> iosKeys = [
    iosAppIdKey,
    iosBannerKey,
    iosInterstitialKey,
  ];

  static const String sampleAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String sampleIosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const String androidBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String iosBannerTestId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';

  static final RegExp appIdPattern = RegExp('^$publisherPrefix~\\d{8,16}\$');
  static final RegExp unitIdPattern = RegExp('^$publisherPrefix/\\d{8,16}\$');

  static bool isAppIdKey(String key) => key.endsWith('_APP_ID');

  static bool isPlaceholder(String raw) {
    final id = raw.trim().toUpperCase();
    if (id.isEmpty) return true;
    return id.contains('TODO') ||
        id.contains('REPLACE') ||
        id.contains('YOUR_') ||
        id.contains('SAMPLE') ||
        id.contains('XXXX') ||
        id.contains('CHANGEME');
  }

  /// True when [raw] is a real unit or app ID for this publisher.
  static bool isValidProductionId(String raw, {required bool appId}) {
    final id = raw.trim();
    if (isPlaceholder(id) || id.contains(samplePublisherFragment)) {
      return false;
    }
    return (appId ? appIdPattern : unitIdPattern).hasMatch(id);
  }

  static List<String> problemsFor(
    Map<String, String> ids, {
    required bool ios,
  }) {
    final keys = ios ? iosKeys : androidKeys;
    final problems = <String>[];
    for (final key in keys) {
      final value = (ids[key] ?? '').trim();
      if (!isValidProductionId(value, appId: isAppIdKey(key))) {
        problems.add(
          '$key is not a production AdMob ID for $publisherPrefix '
          '(got "$value")',
        );
      }
    }
    return problems;
  }
}
