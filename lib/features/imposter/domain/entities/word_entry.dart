import 'package:equatable/equatable.dart';
import '../enums/difficulty.dart';

class WordEntry extends Equatable {
  const WordEntry({
    required this.id,
    required this.difficulty,
    required this.category,
    required this.word,
    required this.hint,
    this.alternateHint,
    this.tags = const [],
  });
  final String id;
  final Difficulty difficulty;
  final String category;
  final String word;
  final String hint;
  final String? alternateHint;
  final List<String> tags;
  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
    id: json['id'] as String,
    difficulty: Difficulty.fromName(json['difficulty'] as String),
    category: (json['category'] as String?) ?? 'general',
    word: json['word'] as String,
    hint: json['hint'] as String,
    alternateHint: json['alternateHint'] as String?,
    tags:
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const [],
  );
  @override
  List<Object?> get props => [
    id,
    difficulty,
    category,
    word,
    hint,
    alternateHint,
    tags,
  ];
  @override
  String toString() => 'WordEntry(id: $id)';
}
