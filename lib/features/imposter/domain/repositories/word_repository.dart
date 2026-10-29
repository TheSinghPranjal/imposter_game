import '../entities/word_entry.dart';
import '../enums/difficulty.dart';

abstract class WordRepository {
  Future<void> load();
  bool get isLoaded;
  String? get loadError;
  List<WordEntry> wordsByDifficulty(Difficulty difficulty);
  WordEntry randomWord(Difficulty difficulty);
  WordEntry randomWordExcluding(Difficulty difficulty, Set<String> excludeIds);

  /// A word from one of [difficulties], each level equally likely, avoiding
  /// recently used words.
  WordEntry randomWordForRound(Set<Difficulty> difficulties);
  List<String> get recentWordIds;
}
