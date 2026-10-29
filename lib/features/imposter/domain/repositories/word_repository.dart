import '../entities/word_entry.dart';
import '../enums/difficulty.dart';

abstract class WordRepository {
  Future<void> load();
  bool get isLoaded;
  String? get loadError;
  List<WordEntry> wordsByDifficulty(Difficulty difficulty);
  WordEntry randomWord(Difficulty difficulty);
  WordEntry randomWordExcluding(Difficulty difficulty, Set<String> excludeIds);
  WordEntry randomWordForRound(Difficulty difficulty);
  List<String> get recentWordIds;
}
