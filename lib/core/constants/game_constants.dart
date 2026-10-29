class GameConstants {
  static const int minPlayers = 3;
  static const int maxPlayers = 20;
  static const int recommendedMin = 4;
  static const int recommendedMax = 10;
  static const int maxNameLength = 20;
  static const int recentWordLimit = 20;
  static const int holdToRevealMs = 800;
  static const int splashDurationMs = 1400;
  static const int protectedPositions = 2;
  static const String wordAssetPath = 'assets/data/imposter_words.json';
  static const int expectedWordCount = 600;
  static const int expectedPerDifficulty = 200;

  static int maxImpostersFor(int playerCount) {
    if (playerCount < minPlayers) return 0;
    final byRatio = playerCount ~/ 3;
    final eligible = (playerCount - protectedPositions).clamp(0, playerCount);
    return byRatio.clamp(0, eligible);
  }

  static String get bestWithLabel =>
      'Best with $recommendedMin–$recommendedMax players';

  /// Show an interstitial only on every Nth Again tap between rounds.
  static const int interstitialEveryNRounds = 4;

  /// Extra quiet period so several fast rounds cannot stack interstitials.
  static const Duration interstitialMinimumInterval = Duration(seconds: 90);

  static const double bannerAdHeight = 50;
}
