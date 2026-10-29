import 'package:equatable/equatable.dart';

import '../enums/app_theme_mode.dart';
import '../enums/difficulty.dart';

class GameSettings extends Equatable {
  const GameSettings({
    this.difficulty = Difficulty.easy,
    this.imposterCount = 1,
    this.showHint = false,
    this.themeMode = AppThemeMode.system,
    this.soundEnabled = false,
    this.hapticEnabled = true,
    this.animationsEnabled = true,
    this.allowDuplicateNames = false,
  });

  final Difficulty difficulty;
  final int imposterCount;
  final bool showHint;
  final AppThemeMode themeMode;
  final bool soundEnabled;
  final bool hapticEnabled;
  final bool animationsEnabled;
  final bool allowDuplicateNames;

  static const defaults = GameSettings();

  GameSettings copyWith({
    Difficulty? difficulty,
    int? imposterCount,
    bool? showHint,
    AppThemeMode? themeMode,
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? animationsEnabled,
    bool? allowDuplicateNames,
  }) {
    return GameSettings(
      difficulty: difficulty ?? this.difficulty,
      imposterCount: imposterCount ?? this.imposterCount,
      showHint: showHint ?? this.showHint,
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      allowDuplicateNames: allowDuplicateNames ?? this.allowDuplicateNames,
    );
  }

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty.name,
    'imposterCount': imposterCount,
    'showHint': showHint,
    'themeMode': themeMode.name,
    'soundEnabled': soundEnabled,
    'hapticEnabled': hapticEnabled,
    'animationsEnabled': animationsEnabled,
    'allowDuplicateNames': allowDuplicateNames,
  };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      difficulty: Difficulty.fromName(json['difficulty'] as String? ?? 'easy'),
      imposterCount: json['imposterCount'] as int? ?? 1,
      showHint: json['showHint'] as bool? ?? false,
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == (json['themeMode'] as String? ?? 'system'),
        orElse: () => AppThemeMode.system,
      ),
      soundEnabled: json['soundEnabled'] as bool? ?? false,
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      animationsEnabled: json['animationsEnabled'] as bool? ?? true,
      allowDuplicateNames: json['allowDuplicateNames'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    difficulty,
    imposterCount,
    showHint,
    themeMode,
    soundEnabled,
    hapticEnabled,
    animationsEnabled,
    allowDuplicateNames,
  ];
}
