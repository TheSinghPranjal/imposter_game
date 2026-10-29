import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/ad_config.dart';
import '../../core/constants/game_constants.dart';
import 'ad_log.dart';
import 'ad_retry.dart';

/// Anchored banner for the menu and the between-rounds screen.
///
/// Keeps a reserved height so those screens do not jump once the ad loads.
/// Debug and profile builds use Google's sample units. Release builds use the
/// production unit from [AdConfig]. Nothing is requested when consent is
/// required and has not been granted. A failed load (including no fill) keeps
/// the slot on screen and retries with backoff.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _banner;
  bool _loaded = false;
  bool _loading = false;
  bool _disposed = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    AdConfig.addCanRequestAdsListener(_onCanRequestAdsChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureLoad();
  }

  void _onCanRequestAdsChanged() {
    if (!mounted) return;
    if (!AdConfig.canRequestAds) {
      _retryTimer?.cancel();
      _retryTimer = null;
      final banner = _banner;
      _banner = null;
      _loaded = false;
      banner?.dispose();
      setState(() {});
      return;
    }
    _ensureLoad();
  }

  void _ensureLoad() {
    if (!mounted || !AdConfig.adsSupported || !AdConfig.canRequestAds) return;
    if (_banner != null || _loading || _retryTimer != null) return;
    unawaited(_load());
  }

  Future<void> _load() async {
    if (_loading || _banner != null) return;
    if (!mounted || !AdConfig.adsSupported || !AdConfig.canRequestAds) return;

    _loading = true;
    try {
      final width = MediaQuery.sizeOf(context).width.truncate();
      AdSize size = AdSize.banner;
      try {
        final adaptive =
            await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              width,
            );
        if (adaptive != null) size = adaptive;
      } catch (error, stack) {
        debugPrint(
          'Adaptive banner size failed: ${describeAdsError(error)}\n$stack',
        );
      }
      if (!mounted || !AdConfig.canRequestAds || _banner != null) return;

      final banner = BannerAd(
        adUnitId: AdConfig.bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _retryAttempt = 0;
            _retryTimer?.cancel();
            _retryTimer = null;
            if (_disposed ||
                !mounted ||
                !AdConfig.canRequestAds ||
                !identical(_banner, ad)) {
              _releaseBanner(ad);
              return;
            }
            setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner failed to load: ${describeAdsError(error)}');
            _dropFailedBanner(ad);
          },
        ),
      );

      _banner = banner;
      debugPrint('Banner load requested: ${AdConfig.bannerAdUnitId}');
      await banner.load();
    } catch (error, stack) {
      debugPrint('Banner load threw: ${describeAdsError(error)}\n$stack');
      final failed = _banner;
      if (failed != null) {
        _dropFailedBanner(failed);
      } else if (mounted && !_disposed) {
        setState(() => _loaded = false);
        _scheduleRetry();
      }
    } finally {
      _loading = false;
    }
  }

  void _releaseBanner(Ad ad) {
    if (!identical(_banner, ad)) return;
    _banner = null;
    ad.dispose();
  }

  void _dropFailedBanner(Ad ad) {
    if (_disposed || !identical(_banner, ad)) return;
    _releaseBanner(ad);
    if (!mounted) return;
    setState(() => _loaded = false);
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (!mounted || !AdConfig.adsSupported || !AdConfig.canRequestAds) return;
    _retryTimer?.cancel();
    final delay = adLoadRetryDelay(_retryAttempt);
    _retryAttempt++;
    debugPrint('Banner retry in ${delay.inSeconds}s (attempt $_retryAttempt)');
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (!mounted) return;
      unawaited(_load());
    });
  }

  @override
  void dispose() {
    _disposed = true;
    AdConfig.removeCanRequestAdsListener(_onCanRequestAdsChanged);
    _retryTimer?.cancel();
    _retryTimer = null;
    final banner = _banner;
    _banner = null;
    banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.adsSupported || !AdConfig.canRequestAds) {
      return const SizedBox.shrink();
    }

    final height = _loaded && _banner != null
        ? _banner!.size.height.toDouble()
        : GameConstants.bannerAdHeight;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: _loaded && _banner != null
            ? AdWidget(ad: _banner!)
            : const ColoredBox(
                color: AppColors.deepNavy,
                child: Center(
                  child: Text(
                    'Loading ad…',
                    style: TextStyle(
                      color: AppColors.offWhite,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
