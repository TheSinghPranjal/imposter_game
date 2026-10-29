enum GamePhase {
  splash,
  home,
  howToPlay,
  playerSetup,
  configuration,
  passPhone,
  readyToReveal,
  revealing,
  revealed,
  allRevealed,
  roundReady,
  settings,
  error,
}

extension GamePhaseX on GamePhase {
  bool get isRevealFlow =>
      this == GamePhase.passPhone ||
      this == GamePhase.readyToReveal ||
      this == GamePhase.revealing ||
      this == GamePhase.revealed;

  bool get showsSecret =>
      this == GamePhase.revealing || this == GamePhase.revealed;

  /// Banners are limited to the home menu and the between-rounds screen.
  /// The pass-the-phone role reveal must never reserve or request an ad.
  bool get showsBanner =>
      this == GamePhase.home || this == GamePhase.roundReady;
}
