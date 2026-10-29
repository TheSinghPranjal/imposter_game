import 'package:flutter/services.dart';

class HapticService {
  const HapticService({this.enabled = true});

  final bool enabled;

  Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> selection() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> medium() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }
}
