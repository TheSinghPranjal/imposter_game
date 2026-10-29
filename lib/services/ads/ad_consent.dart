/// Whether the latest UMP refresh produced a usable consent decision.
///
/// A failed or timed-out check is not the same thing as the user denying ads.
enum AdsConsentStatus { unknown, notRequired, required, obtained }

/// Pure UMP outcome used to decide if an ad request is allowed.
class AdsConsentDecision {
  const AdsConsentDecision({
    required this.allowAdRequests,
    required this.reason,
  });

  final bool allowAdRequests;
  final String reason;
}

/// Decides if this session may call Mobile Ads and load units.
///
/// Ads stay off only when the user denied them, or consent is required and
/// has not been obtained. A missing, failed, or timed-out UMP check (the
/// usual result outside the EEA when no message is published, or when the
/// request never returns) is not a denial, so ad requests stay allowed.
AdsConsentDecision decideAdsConsent({
  required AdsConsentStatus? status,
  required bool? canRequestAds,
  required bool updateFailedOrTimedOut,
}) {
  if (status == AdsConsentStatus.obtained && canRequestAds == false) {
    return const AdsConsentDecision(
      allowAdRequests: false,
      reason: 'consent obtained but ads were denied',
    );
  }
  if (status == AdsConsentStatus.notRequired) {
    return const AdsConsentDecision(
      allowAdRequests: true,
      reason: 'consent not required',
    );
  }
  if (canRequestAds == true) {
    return const AdsConsentDecision(
      allowAdRequests: true,
      reason: 'canRequestAds=true',
    );
  }
  if (status == AdsConsentStatus.required) {
    return const AdsConsentDecision(
      allowAdRequests: false,
      reason: 'consent required and not obtained',
    );
  }
  if (updateFailedOrTimedOut ||
      status == null ||
      status == AdsConsentStatus.unknown ||
      canRequestAds == null) {
    return AdsConsentDecision(
      allowAdRequests: true,
      reason: updateFailedOrTimedOut
          ? 'ump check failed or timed out without a denial'
          : 'consent unknown and not denied',
    );
  }
  return const AdsConsentDecision(
    allowAdRequests: false,
    reason: 'consent not granted',
  );
}
