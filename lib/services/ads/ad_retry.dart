/// Delay before the next banner or interstitial load after a failure.
///
/// Starts at 5 seconds and doubles until 60 seconds so a no-fill is retried
/// without hammering AdMob.
Duration adLoadRetryDelay(int attempt) {
  final exponent = attempt.clamp(0, 4);
  final seconds = 5 * (1 << exponent);
  return Duration(seconds: seconds > 60 ? 60 : seconds);
}
