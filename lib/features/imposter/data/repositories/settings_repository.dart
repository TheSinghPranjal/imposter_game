import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/game_settings.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'find_imposter_settings_v1';

  GameSettings load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return GameSettings.defaults;
    try {
      return GameSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return GameSettings.defaults;
    }
  }

  Future<void> save(GameSettings settings) async {
    await _prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  Future<void> reset() async => _prefs.remove(_key);
}
