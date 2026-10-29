import '../../features/imposter/domain/entities/word_entry.dart';
import '../../features/imposter/domain/enums/difficulty.dart';
import '../constants/game_constants.dart';

class WordValidationException implements Exception {
  WordValidationException(this.message);
  final String message;
  @override
  String toString() => 'WordValidationException: $message';
}

class WordPackValidator {
  const WordPackValidator();

  void validate(List<WordEntry> entries, {required bool throwOnError}) {
    final errors = <String>[];
    if (entries.length != GameConstants.expectedWordCount) {
      errors.add(
        'Expected ${GameConstants.expectedWordCount} words, got ${entries.length}.',
      );
    }
    for (final d in Difficulty.values) {
      final count = entries.where((e) => e.difficulty == d).length;
      if (count != GameConstants.expectedPerDifficulty) {
        errors.add(
          'Expected ${GameConstants.expectedPerDifficulty} ${d.name}, got $count.',
        );
      }
    }
    final ids = <String>{};
    final words = <String>{};
    for (final e in entries) {
      if (e.id.trim().isEmpty) errors.add('Empty id.');
      if (e.word.trim().isEmpty) errors.add('Empty word for ${e.id}.');
      if (e.hint.trim().isEmpty) errors.add('Empty hint for ${e.id}.');
      if (!ids.add(e.id)) errors.add('Duplicate id: ${e.id}.');
      final wk = e.word.trim().toLowerCase();
      if (!words.add(wk)) errors.add('Duplicate word: ${e.word}.');
      final hk = e.hint.trim().toLowerCase();
      if (hk == wk) errors.add('Hint equals word for ${e.id}.');
      if (hk.contains(wk)) errors.add('Hint contains word for ${e.id}.');
    }
    if (errors.isEmpty) return;
    final msg = errors.take(12).join('\n');
    if (throwOnError) throw WordValidationException(msg);
  }
}
