import 'package:equatable/equatable.dart';

import '../enums/app_theme_mode.dart';
import '../enums/difficulty.dart';

class GameSettings extends Equatable {
  const GameSettings({
    this.difficulties = const {Difficulty.easy},
    this.imposterCount = 1,
    this.showHint = false,
    this.themeMode = AppThemeMode.system,
    this.soundEnabled = false,
    this.hapticEnabled = true,
    this.animationsEnabled = true,
    this.allowDuplicateNames = false,
    this.wordShuffleEnabled = true,
  });

  /// Levels a new game draws its word from. Never empty.
  final Set<Difficulty> difficulties;
  final int imposterCount;
  final bool showHint;
  final AppThemeMode themeMode;
  final bool soundEnabled;
  final bool hapticEnabled;
  final bool animationsEnabled;
  final bool allowDuplicateNames;

  /// The first player in the reveal order may shuffle the secret word for
  /// everyone, and is never the imposter while this is on.
  final bool wordShuffleEnabled;

  static const defaults = GameSettings();

  GameSettings copyWith({
    Set<Difficulty>? difficulties,
    int? imposterCount,
    bool? showHint,
    AppThemeMode? themeMode,
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? animationsEnabled,
    bool? allowDuplicateNames,
    bool? wordShuffleEnabled,
  }) {
    return GameSettings(
      difficulties: difficulties ?? this.difficulties,
      imposterCount: imposterCount ?? this.imposterCount,
      showHint: showHint ?? this.showHint,
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      allowDuplicateNames: allowDuplicateNames ?? this.allowDuplicateNames,
      wordShuffleEnabled: wordShuffleEnabled ?? this.wordShuffleEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'difficulties': [
      for (final d in Difficulty.values)
        if (difficulties.contains(d)) d.name,
    ],
    'imposterCount': imposterCount,
    'showHint': showHint,
    'themeMode': themeMode.name,
    'soundEnabled': soundEnabled,
    'hapticEnabled': hapticEnabled,
    'animationsEnabled': animationsEnabled,
    'allowDuplicateNames': allowDuplicateNames,
    'wordShuffleEnabled': wordShuffleEnabled,
  };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      difficulties: _difficultiesFromJson(json),
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
      wordShuffleEnabled: json['wordShuffleEnabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    difficulties,
    imposterCount,
    showHint,
    themeMode,
    soundEnabled,
    hapticEnabled,
    animationsEnabled,
    allowDuplicateNames,
    wordShuffleEnabled,
  ];

  /// Reads the saved levels, falling back to the single `difficulty` saved by
  /// earlier versions, then to easy.
  static Set<Difficulty> _difficultiesFromJson(Map<String, dynamic> json) {
    final saved = json['difficulties'];
    if (saved is List) {
      final set = {for (final name in saved) Difficulty.fromName('$name')};
      if (set.isNotEmpty) return set;
    }
    return {Difficulty.fromName(json['difficulty'] as String? ?? 'easy')};
  }
}
