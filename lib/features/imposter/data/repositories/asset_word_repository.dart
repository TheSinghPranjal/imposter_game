import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/utils/word_pack_validator.dart';
import '../../domain/entities/word_entry.dart';
import '../../domain/enums/difficulty.dart';
import '../../domain/repositories/word_repository.dart';

class AssetWordRepository implements WordRepository {
  AssetWordRepository({
    Random? random,
    WordPackValidator validator = const WordPackValidator(),
    AssetBundle? bundle,
  }) : _random = random ?? Random(),
       _validator = validator,
       _bundle = bundle ?? rootBundle;

  final Random _random;
  final WordPackValidator _validator;
  final AssetBundle _bundle;
  List<WordEntry> _words = const [];
  final List<String> _recent = [];
  bool _loaded = false;
  String? _error;

  @override
  bool get isLoaded => _loaded;
  @override
  String? get loadError => _error;
  @override
  List<String> get recentWordIds => List.unmodifiable(_recent);

  @override
  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await _bundle.loadString(GameConstants.wordAssetPath);
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entries = decoded
          .map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      try {
        _validator.validate(entries, throwOnError: true);
      } on WordValidationException catch (e) {
        if (kDebugMode) rethrow;
        _error = 'Something went wrong loading the word pack.';
        debugPrint(e.message);
      }
      _words = List.unmodifiable(entries);
      _loaded = true;
    } catch (_) {
      _error = 'Something went wrong loading the word pack.';
      _loaded = false;
      if (kDebugMode) rethrow;
    }
  }

  @override
  List<WordEntry> wordsByDifficulty(Difficulty difficulty) {
    _ensure();
    return _words.where((w) => w.difficulty == difficulty).toList();
  }

  @override
  WordEntry randomWord(Difficulty difficulty) =>
      randomWordExcluding(difficulty, const {});

  @override
  WordEntry randomWordExcluding(Difficulty difficulty, Set<String> excludeIds) {
    _ensure();
    var pool = wordsByDifficulty(
      difficulty,
    ).where((w) => !excludeIds.contains(w.id)).toList();
    if (pool.isEmpty) pool = wordsByDifficulty(difficulty);
    if (pool.isEmpty) throw StateError('No words for ${difficulty.name}');
    return pool[_random.nextInt(pool.length)];
  }

  @override
  WordEntry randomWordForRound(Difficulty difficulty) {
    _ensure();
    var pool = wordsByDifficulty(
      difficulty,
    ).where((w) => !_recent.contains(w.id)).toList();
    if (pool.isEmpty) {
      final remove = (_recent.length / 2).ceil().clamp(1, _recent.length);
      if (_recent.isNotEmpty) _recent.removeRange(0, remove);
      pool = wordsByDifficulty(
        difficulty,
      ).where((w) => !_recent.contains(w.id)).toList();
    }
    if (pool.isEmpty) pool = wordsByDifficulty(difficulty);
    final word = pool[_random.nextInt(pool.length)];
    _recent.add(word.id);
    if (_recent.length > GameConstants.recentWordLimit) _recent.removeAt(0);
    return word;
  }

  void seedForTests(List<WordEntry> words) {
    _words = List.unmodifiable(words);
    _loaded = true;
    _error = null;
    _recent.clear();
  }

  void _ensure() {
    if (!_loaded) throw StateError('Word repository not loaded');
  }
}
