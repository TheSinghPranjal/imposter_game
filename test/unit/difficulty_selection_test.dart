import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/core/utils/round_generator.dart';
import 'package:imposter_game/features/imposter/data/repositories/asset_word_repository.dart';
import 'package:imposter_game/features/imposter/domain/entities/game_settings.dart';
import 'package:imposter_game/features/imposter/domain/entities/word_entry.dart';
import 'package:imposter_game/features/imposter/domain/enums/difficulty.dart';
import 'package:imposter_game/features/imposter/presentation/providers/game_controller.dart';

AssetWordRepository makeWords() {
  final words = AssetWordRepository(random: Random(4));
  words.seedForTests([
    for (final d in Difficulty.values)
      for (var i = 0; i < 30; i++)
        WordEntry(
          id: '${d.name}_$i',
          difficulty: d,
          category: 'x',
          word: '${d.name}Word$i',
          hint: 'Hint$i',
        ),
  ]);
  return words;
}

void main() {
  test('defaults to easy only', () {
    expect(GameSettings.defaults.difficulties, {Difficulty.easy});
  });

  test('saved levels round-trip, and old single difficulty migrates', () {
    const settings = GameSettings(
      difficulties: {Difficulty.easy, Difficulty.hard},
    );
    expect(GameSettings.fromJson(settings.toJson()).difficulties, {
      Difficulty.easy,
      Difficulty.hard,
    });
    expect(GameSettings.fromJson({'difficulty': 'medium'}).difficulties, {
      Difficulty.medium,
    });
    expect(GameSettings.fromJson({}).difficulties, {Difficulty.easy});
  });

  test('the last selected level cannot be turned off', () async {
    final controller = GameController(wordRepository: makeWords());
    await controller.toggleDifficulty(Difficulty.easy);
    expect(controller.state.settings.difficulties, {Difficulty.easy});
    await controller.toggleDifficulty(Difficulty.hard);
    await controller.toggleDifficulty(Difficulty.easy);
    expect(controller.state.settings.difficulties, {Difficulty.hard});
  });

  test('new games draw words only from the selected levels', () async {
    final controller = GameController(
      wordRepository: makeWords(),
      roundGenerator: RoundGenerator(random: Random(6)),
    );
    for (final name in ['Ava', 'Ben', 'Cleo']) {
      controller.addPlayer(name);
    }
    controller.goToConfiguration();
    await controller.toggleDifficulty(Difficulty.hard);

    final seen = <Difficulty>{};
    for (var i = 0; i < 60; i++) {
      await controller.startRound();
      final round = controller.state.round!;
      expect(round.secretWord.difficulty, isNot(Difficulty.medium));
      expect(round.difficulty, round.secretWord.difficulty);
      seen.add(round.secretWord.difficulty);
    }
    expect(seen, {Difficulty.easy, Difficulty.hard});
  });
}
