enum Difficulty {
  easy,
  medium,
  hard;

  String get label => switch (this) {
    Difficulty.easy => 'Easy',
    Difficulty.medium => 'Medium',
    Difficulty.hard => 'Difficult',
  };

  String get emoji => switch (this) {
    Difficulty.easy => '🟢',
    Difficulty.medium => '🟡',
    Difficulty.hard => '🔴',
  };

  static Difficulty fromName(String value) {
    final v = value.toLowerCase();
    if (v == 'difficult' || v == 'hard') return Difficulty.hard;
    return Difficulty.values.firstWhere(
      (d) => d.name == v,
      orElse: () => Difficulty.easy,
    );
  }
}
