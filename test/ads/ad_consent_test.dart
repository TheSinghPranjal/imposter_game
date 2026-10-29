import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/services/ads/ad_consent.dart';
import 'package:imposter_game/services/ads/ad_retry.dart';

void main() {
  AdsConsentDecision decide({
    AdsConsentStatus? status,
    bool? canRequestAds,
    bool updateFailedOrTimedOut = false,
  }) {
    return decideAdsConsent(
      status: status,
      canRequestAds: canRequestAds,
      updateFailedOrTimedOut: updateFailedOrTimedOut,
    );
  }

  test(
    'allows ads when UMP is not required even if canRequestAds is false',
    () {
      final decision = decide(
        status: AdsConsentStatus.notRequired,
        canRequestAds: false,
      );
      expect(decision.allowAdRequests, isTrue);
      expect(decision.reason, 'consent not required');
    },
  );

  test('allows ads when the UMP check fails or times out without a denial', () {
    final unknown = decide(
      status: AdsConsentStatus.unknown,
      canRequestAds: false,
      updateFailedOrTimedOut: true,
    );
    final unread = decide(
      status: null,
      canRequestAds: null,
      updateFailedOrTimedOut: true,
    );
    expect(unknown.allowAdRequests, isTrue);
    expect(unread.allowAdRequests, isTrue);
    expect(unknown.reason, 'ump check failed or timed out without a denial');
  });

  test('keeps ads off when consent is required and has not been obtained', () {
    final fresh = decide(
      status: AdsConsentStatus.required,
      canRequestAds: false,
    );
    final cachedAfterFailure = decide(
      status: AdsConsentStatus.required,
      canRequestAds: false,
      updateFailedOrTimedOut: true,
    );
    expect(fresh.allowAdRequests, isFalse);
    expect(fresh.reason, 'consent required and not obtained');
    expect(cachedAfterFailure.allowAdRequests, isFalse);
  });

  test('keeps ads off when the user denied ads after obtaining consent', () {
    final decision = decide(
      status: AdsConsentStatus.obtained,
      canRequestAds: false,
      updateFailedOrTimedOut: true,
    );
    expect(decision.allowAdRequests, isFalse);
    expect(decision.reason, 'consent obtained but ads were denied');
  });

  test('allows ads when consent was obtained and ads may be requested', () {
    expect(
      decide(
        status: AdsConsentStatus.obtained,
        canRequestAds: true,
      ).allowAdRequests,
      isTrue,
    );
    expect(
      decide(
        status: AdsConsentStatus.unknown,
        canRequestAds: true,
        updateFailedOrTimedOut: true,
      ).allowAdRequests,
      isTrue,
    );
  });

  test('banner and interstitial retries back off and then cap', () {
    expect(adLoadRetryDelay(0), const Duration(seconds: 5));
    expect(adLoadRetryDelay(1), const Duration(seconds: 10));
    expect(adLoadRetryDelay(2), const Duration(seconds: 20));
    expect(adLoadRetryDelay(3), const Duration(seconds: 40));
    expect(adLoadRetryDelay(4), const Duration(seconds: 60));
    expect(adLoadRetryDelay(8), const Duration(seconds: 60));
  });
}
