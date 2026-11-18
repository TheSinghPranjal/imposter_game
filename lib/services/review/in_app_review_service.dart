import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts finished rounds and, when the player has earned it, asks the
/// store to show its in-app review prompt.
abstract class InAppReviewService {
  /// Called once a round has reached the between-rounds screen.
  ///
  /// Never call this mid-round. Implementations must not throw.
  Future<void> onRoundCompleted();
}

final inAppReviewServiceProvider = Provider<InAppReviewService>((ref) {
  return const NoopInAppReviewService();
});

/// Used in tests and whenever the store review API is not wired up.
class NoopInAppReviewService implements InAppReviewService {
  const NoopInAppReviewService();

  @override
  Future<void> onRoundCompleted() async {}
}

/// Records completed rounds in [SharedPreferences] and requests a review
/// after the 3rd finished round, at most once every 30 days.
class StoreInAppReviewService implements InAppReviewService {
  StoreInAppReviewService({
    required SharedPreferences prefs,
    InAppReview? review,
    Future<bool> Function()? isAvailable,
    Future<void> Function()? requestReview,
    DateTime Function()? now,
  }) : _prefs = prefs,
       _isAvailable =
           isAvailable ??
           (() => (review ?? InAppReview.instance).isAvailable()),
       _requestReview =
           requestReview ??
           (() => (review ?? InAppReview.instance).requestReview()),
       _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final Future<bool> Function() _isAvailable;
  final Future<void> Function() _requestReview;
  final DateTime Function() _now;

  static const completedRoundsKey = 'in_app_review_completed_rounds';
  static const lastPromptAtKey = 'in_app_review_last_prompt_at';
  static const minCompletedRounds = 3;
  static const cooldown = Duration(days: 30);

  @override
  Future<void> onRoundCompleted() async {
    try {
      final completed = (_prefs.getInt(completedRoundsKey) ?? 0) + 1;
      await _prefs.setInt(completedRoundsKey, completed);
      if (completed < minCompletedRounds) return;

      final lastMs = _prefs.getInt(lastPromptAtKey);
      if (lastMs != null) {
        final elapsed = _now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastMs),
        );
        if (elapsed < cooldown) return;
      }

      if (!await _isAvailable()) return;

      await _requestReview();
      await _prefs.setInt(lastPromptAtKey, _now().millisecondsSinceEpoch);
    } catch (_) {
      // A store-API failure must never interrupt the between-rounds screen.
    }
  }
}
