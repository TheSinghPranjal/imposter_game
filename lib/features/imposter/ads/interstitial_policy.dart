import '../../../core/constants/game_constants.dart';

/// When an "Again" tap may show an interstitial.
///
/// Requires both a round cadence and a minimum quiet period so fast rounds
/// cannot stack full-screen ads. Callers must only ask this between rounds,
/// never during the pass-the-phone reveal flow.
class InterstitialPolicy {
  InterstitialPolicy._();

  static bool shouldShow({
    required bool fromNextRound,
    required int roundsPlayed,
    required DateTime? lastShownAt,
    required DateTime now,
  }) {
    if (!fromNextRound) return false;
    if (roundsPlayed <= 0 ||
        roundsPlayed % GameConstants.interstitialEveryNRounds != 0) {
      return false;
    }
    final last = lastShownAt;
    if (last != null &&
        now.difference(last) < GameConstants.interstitialMinimumInterval) {
      return false;
    }
    return true;
  }
}
