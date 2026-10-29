import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_config.dart';
import 'ad_consent.dart';
import 'ad_log.dart';
import 'ad_retry.dart';

abstract class AdsService {
  Future<void> initialize();
  Future<bool> showInterstitial();
  bool get isInitialized;

  /// True when UMP requires a privacy-options entry point (EEA/UK and similar).
  Future<bool> get privacyOptionsRequired;

  Future<void> showPrivacyOptions();
}

final adsServiceProvider = Provider<AdsService>((ref) {
  if (AdConfig.adsSupported) {
    return MobileAdsService(isTestMode: AdConfig.isTestMode);
  }
  return FakeAdsService();
});

/// Used in widget tests and on platforms where AdMob is unavailable.
class FakeAdsService implements AdsService {
  FakeAdsService({this.interstitialSucceeds = false});

  bool interstitialSucceeds;
  bool _initialized = false;
  int interstitialRequests = 0;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> showInterstitial() async {
    interstitialRequests++;
    return interstitialSucceeds;
  }

  @override
  Future<bool> get privacyOptionsRequired async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}

/// Why the UMP refresh itself did not finish cleanly.
enum _ConsentUpdateFailure { none, requestFailed, timedOut }

class _ConsentGatherResult {
  const _ConsentGatherResult({
    required this.failure,
    this.errorCode,
    this.errorMessage,
  });

  final _ConsentUpdateFailure failure;
  final int? errorCode;
  final String? errorMessage;
}

class _ConsentSnapshot {
  const _ConsentSnapshot({
    required this.status,
    required this.canRequestAds,
    required this.updateFailedOrTimedOut,
    this.errorCode,
    this.errorMessage,
  });

  final AdsConsentStatus? status;
  final bool? canRequestAds;
  final bool updateFailedOrTimedOut;
  final int? errorCode;
  final String? errorMessage;
}

/// Real AdMob implementation.
///
/// Debug and profile builds request Google sample units. Release builds
/// request the production units from [AdConfig]. Mobile Ads is initialized
/// after the UMP check unless consent was required and not granted.
class MobileAdsService implements AdsService {
  MobileAdsService({required this.isTestMode});

  final bool isTestMode;
  bool _initialized = false;
  bool _initializing = false;
  int _initAttempts = 0;
  Timer? _initRetry;

  InterstitialAd? _interstitialAd;
  Completer<InterstitialAd?>? _interstitialLoad;
  Timer? _interstitialRetry;
  int _interstitialAttempts = 0;
  bool _showingInterstitial = false;

  int _consentEpoch = 0;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (!AdConfig.adsSupported) {
      _initialized = false;
      AdConfig.canRequestAds = false;
      debugPrint('AdMob: ads are not supported on this platform.');
      return;
    }

    try {
      final gather = await _gatherConsent();
      final allowed = await _resolveAndPublish(gather);
      if (!allowed) return;
    } catch (error, stack) {
      debugPrint(
        'AdMob consent flow failed: ${describeAdsError(error)}\n$stack',
      );
      // An exception while reading consent is not a denial.
      AdConfig.canRequestAds = true;
      await _initializeMobileAds();
    }
  }

  /// UMP consent before the first ad request. A failed or slow update must not
  /// hang startup and must not be treated as a denial by itself.
  Future<_ConsentGatherResult> _gatherConsent() async {
    final completer = Completer<_ConsentGatherResult>();
    var settled = false;

    void finish(_ConsentGatherResult result) {
      if (settled) {
        unawaited(_resolveAndPublish(result, lateUpdate: true));
        return;
      }
      settled = true;
      if (!completer.isCompleted) completer.complete(result);
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          FormError? formError;
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((error) {
              formError = error;
              if (error != null) {
                debugPrint(
                  'Consent form dismissed with error: '
                  'code=${error.errorCode} message=${error.message}',
                );
              }
            });
          } catch (error, stack) {
            debugPrint(
              'Consent form failed: ${describeAdsError(error)}\n$stack',
            );
          }
          finish(
            _ConsentGatherResult(
              failure: _ConsentUpdateFailure.none,
              errorCode: formError?.errorCode,
              errorMessage: formError?.message,
            ),
          );
        },
        (error) {
          debugPrint(
            'Consent info update failed: '
            'code=${error.errorCode} message=${error.message}',
          );
          finish(
            _ConsentGatherResult(
              failure: _ConsentUpdateFailure.requestFailed,
              errorCode: error.errorCode,
              errorMessage: error.message,
            ),
          );
        },
      );
    } catch (error, stack) {
      debugPrint(
        'Consent info update threw: ${describeAdsError(error)}\n$stack',
      );
      return _ConsentGatherResult(
        failure: _ConsentUpdateFailure.requestFailed,
        errorMessage: describeAdsError(error),
      );
    }

    try {
      return await completer.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      settled = true;
      debugPrint(
        'Consent request timed out after 8s; '
        'continuing unless consent was denied.',
      );
      return const _ConsentGatherResult(
        failure: _ConsentUpdateFailure.timedOut,
      );
    }
  }

  Future<bool> _resolveAndPublish(
    _ConsentGatherResult gather, {
    bool lateUpdate = false,
  }) async {
    final epoch = ++_consentEpoch;
    final snapshot = await _snapshotFrom(gather);
    if (epoch != _consentEpoch) return AdConfig.canRequestAds;

    final decision = decideAdsConsent(
      status: snapshot.status,
      canRequestAds: snapshot.canRequestAds,
      updateFailedOrTimedOut: snapshot.updateFailedOrTimedOut,
    );
    debugPrint(
      'AdMob consent${lateUpdate ? ' (late)' : ''}: '
      'status=${snapshot.status?.name ?? 'unread'} '
      'canRequestAds=${snapshot.canRequestAds} '
      'updateFailedOrTimedOut=${snapshot.updateFailedOrTimedOut} '
      'errorCode=${snapshot.errorCode} '
      'errorMessage=${snapshot.errorMessage} '
      'allow=${decision.allowAdRequests} '
      'reason=${decision.reason}',
    );

    if (!decision.allowAdRequests) {
      AdConfig.canRequestAds = false;
      _stopAdsAfterConsentBlock(decision.reason);
      return false;
    }

    AdConfig.canRequestAds = true;
    if (!_initialized) await _initializeMobileAds();
    return true;
  }

  Future<_ConsentSnapshot> _snapshotFrom(_ConsentGatherResult gather) async {
    AdsConsentStatus? status;
    bool? canRequest;
    var failed = gather.failure != _ConsentUpdateFailure.none;

    try {
      status = _mapConsentStatus(
        await ConsentInformation.instance.getConsentStatus(),
      );
    } catch (error, stack) {
      failed = true;
      debugPrint(
        'Consent status read failed: ${describeAdsError(error)}\n$stack',
      );
    }

    try {
      canRequest = await ConsentInformation.instance.canRequestAds();
    } catch (error, stack) {
      failed = true;
      debugPrint(
        'canRequestAds read failed: ${describeAdsError(error)}\n$stack',
      );
    }

    return _ConsentSnapshot(
      status: status,
      canRequestAds: canRequest,
      updateFailedOrTimedOut: failed,
      errorCode: gather.errorCode,
      errorMessage: gather.errorMessage,
    );
  }

  void _stopAdsAfterConsentBlock(String reason) {
    debugPrint('AdMob: skipping ads because $reason.');
    _initialized = false;
    _initRetry?.cancel();
    _interstitialRetry?.cancel();
    if (_showingInterstitial) return;
    final pending = _interstitialAd;
    _interstitialAd = null;
    pending?.dispose();
  }

  Future<void> _initializeMobileAds() async {
    if (_initialized || _initializing || !AdConfig.canRequestAds) return;
    _initializing = true;
    try {
      final InitializationStatus status = await MobileAds.instance.initialize();
      if (!AdConfig.canRequestAds) {
        debugPrint(
          'AdMob initialize finished after consent blocked ads. '
          'No ad request will be made.',
        );
        return;
      }
      _logInitialization(status);
      _initialized = true;
      _initAttempts = 0;
      _initRetry?.cancel();
      debugPrint(
        'AdMob ${isTestMode ? 'TEST' : 'RELEASE'} ready '
        'banner=${AdConfig.bannerAdUnitId} '
        'interstitial=${AdConfig.interstitialAdUnitId}',
      );
      unawaited(_loadInterstitial());
    } catch (error, stack) {
      _initAttempts++;
      debugPrint(
        'AdMob initialize failed: ${describeAdsError(error)} '
        '(attempt $_initAttempts)\n$stack',
      );
      _scheduleInitRetry();
    } finally {
      _initializing = false;
    }
  }

  void _logInitialization(InitializationStatus status) {
    if (status.adapterStatuses.isEmpty) {
      debugPrint('AdMob initialize completed with no adapter status.');
      return;
    }
    for (final entry in status.adapterStatuses.entries) {
      final adapter = entry.value;
      debugPrint(
        'AdMob adapter ${entry.key}: state=${adapter.state.name} '
        'latency=${adapter.latency} description=${adapter.description}',
      );
      if (adapter.state != AdapterInitializationState.ready) {
        debugPrint(
          'AdMob adapter not ready: ${entry.key} '
          'description=${adapter.description}',
        );
      }
    }
  }

  void _scheduleInitRetry() {
    if (!AdConfig.canRequestAds) return;
    _initRetry?.cancel();
    final delay = adLoadRetryDelay(_initAttempts - 1);
    debugPrint('AdMob initialize retry in ${delay.inSeconds}s');
    _initRetry = Timer(delay, () {
      unawaited(_initializeMobileAds());
    });
  }

  AdsConsentStatus _mapConsentStatus(ConsentStatus status) {
    switch (status) {
      case ConsentStatus.notRequired:
        return AdsConsentStatus.notRequired;
      case ConsentStatus.obtained:
        return AdsConsentStatus.obtained;
      case ConsentStatus.required:
        return AdsConsentStatus.required;
      case ConsentStatus.unknown:
        return AdsConsentStatus.unknown;
    }
  }

  @override
  Future<bool> get privacyOptionsRequired async {
    if (!AdConfig.adsSupported) return false;
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (error, stack) {
      debugPrint(
        'Privacy options status failed: ${describeAdsError(error)}\n$stack',
      );
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() {
    return ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        debugPrint(
          'Privacy options form error: '
          'code=${error.errorCode} message=${error.message}',
        );
      }
    });
  }

  AdRequest get _request => const AdRequest();

  Future<InterstitialAd?> _loadInterstitial() {
    if (!AdConfig.canRequestAds) return Future.value();
    if (_interstitialAd != null) return Future.value(_interstitialAd);
    if (_interstitialLoad != null) return _interstitialLoad!.future;

    final completer = Completer<InterstitialAd?>();
    _interstitialLoad = completer;
    debugPrint('Interstitial load requested: ${AdConfig.interstitialAdUnitId}');

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: _request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoad = null;
          _interstitialAttempts = 0;
          _interstitialRetry?.cancel();
          if (!AdConfig.canRequestAds) {
            ad.dispose();
            if (!completer.isCompleted) completer.complete(null);
            return;
          }
          _interstitialAd = ad;
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: ${describeAdsError(error)}');
          _interstitialAd = null;
          _interstitialLoad = null;
          if (!completer.isCompleted) completer.complete(null);
          _scheduleInterstitialRetry();
        },
      ),
    );

    return completer.future;
  }

  void _scheduleInterstitialRetry() {
    if (!AdConfig.canRequestAds) return;
    _interstitialRetry?.cancel();
    final delay = adLoadRetryDelay(_interstitialAttempts);
    _interstitialAttempts++;
    debugPrint('Interstitial retry in ${delay.inSeconds}s');
    _interstitialRetry = Timer(delay, () {
      if (!AdConfig.canRequestAds) return;
      unawaited(_loadInterstitial());
    });
  }

  @override
  Future<bool> showInterstitial() async {
    if (!_initialized || !AdConfig.canRequestAds) return false;
    // Wait briefly for a preload, then continue the round. The Google SDK
    // close control dismisses the ad; nothing here delays that.
    final ad =
        _interstitialAd ??
        await _loadInterstitial().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint(
              'Interstitial was not ready at the break; '
              'continuing without blocking.',
            );
            return null;
          },
        );
    if (ad == null || !AdConfig.canRequestAds) return false;
    _interstitialAd = null;

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _showingInterstitial = false;
        ad.dispose();
        if (!completer.isCompleted) completer.complete(true);
        if (AdConfig.canRequestAds) unawaited(_loadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show: ${describeAdsError(error)}');
        _showingInterstitial = false;
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
        if (AdConfig.canRequestAds) unawaited(_loadInterstitial());
      },
    );
    try {
      _showingInterstitial = true;
      await ad.show();
    } catch (error, stack) {
      debugPrint('Interstitial show threw: ${describeAdsError(error)}\n$stack');
      _showingInterstitial = false;
      ad.dispose();
      if (!completer.isCompleted) completer.complete(false);
      if (AdConfig.canRequestAds) unawaited(_loadInterstitial());
      return false;
    }
    return completer.future;
  }
}
