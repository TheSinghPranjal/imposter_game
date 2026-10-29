import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/core/constants/game_constants.dart';
import 'package:imposter_game/features/imposter/ads/interstitial_policy.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);

  bool show({
    bool fromNextRound = true,
    int roundsPlayed = 4,
    DateTime? lastShownAt,
  }) {
    return InterstitialPolicy.shouldShow(
      fromNextRound: fromNextRound,
      roundsPlayed: roundsPlayed,
      lastShownAt: lastShownAt,
      now: now,
    );
  }

  test('shows on every 4th between-rounds tap after a quiet period', () {
    expect(show(roundsPlayed: 4), isTrue);
    expect(show(roundsPlayed: 8), isTrue);
    expect(show(roundsPlayed: 3), isFalse);
    expect(show(roundsPlayed: 0), isFalse);
    expect(show(fromNextRound: false), isFalse);
  });

  test('skips when the previous interstitial was too recent', () {
    expect(
      show(lastShownAt: now.subtract(const Duration(seconds: 30))),
      isFalse,
    );
    expect(
      show(
        lastShownAt: now.subtract(GameConstants.interstitialMinimumInterval),
      ),
      isTrue,
    );
  });
}
