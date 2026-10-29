import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/core/utils/round_generator.dart';
import 'package:imposter_game/features/imposter/data/repositories/asset_word_repository.dart';
import 'package:imposter_game/features/imposter/domain/entities/word_entry.dart';
import 'package:imposter_game/features/imposter/domain/enums/difficulty.dart';
import 'package:imposter_game/features/imposter/domain/enums/game_phase.dart';
import 'package:imposter_game/features/imposter/presentation/providers/game_controller.dart';

GameController makeController() {
  final words = AssetWordRepository(random: Random(1));
  words.seedForTests([
    for (var i = 0; i < 30; i++)
      WordEntry(
        id: 'easy_$i',
        difficulty: Difficulty.easy,
        category: 'x',
        word: 'Word$i',
        hint: 'Hint$i',
      ),
  ]);
  final controller = GameController(
    wordRepository: words,
    roundGenerator: RoundGenerator(random: Random(2)),
  );
  for (final name in ['Ava', 'Ben', 'Cleo', 'Dev', 'Eli', 'Fay']) {
    controller.addPlayer(name);
  }
  controller.goToConfiguration();
  return controller;
}

void main() {
  test('only the first player can shuffle, and it changes the word', () async {
    final controller = makeController();
    await controller.startRound();
    final first = controller.state.round!;
    expect(first.imposterIds, isNot(contains(first.players.first.id)));

    controller.confirmReadyToReveal();
    expect(controller.state.canShuffleWord, isFalse);
    controller.revealCurrentPlayer();
    expect(controller.state.canShuffleWord, isTrue);

    controller.shuffleWord();
    final shuffled = controller.state.round!;
    expect(shuffled.secretWord.id, isNot(first.secretWord.id));
    expect(shuffled.imposterIds, first.imposterIds);
    expect(controller.state.currentAssignment!.word, shuffled.secretWord.word);

    controller.passToNextPlayer();
    controller.confirmReadyToReveal();
    controller.revealCurrentPlayer();
    expect(controller.state.phase, GamePhase.revealed);
    expect(controller.state.canShuffleWord, isFalse);
    controller.shuffleWord();
    expect(controller.state.round!.secretWord.id, shuffled.secretWord.id);
  });

  test('turning shuffle off hides the button for everyone', () async {
    final controller = makeController();
    await controller.setWordShuffleEnabled(false);
    await controller.startRound();
    controller.confirmReadyToReveal();
    controller.revealCurrentPlayer();
    expect(controller.state.canShuffleWord, isFalse);
  });

  test('each new game starts from a different player', () async {
    final controller = makeController();
    String? previous;
    for (var i = 0; i < 20; i++) {
      await controller.startRound();
      final order = controller.state.round!.players;
      expect(order.first.id, isNot(previous));
      expect(controller.state.currentPlayer, order.first);
      previous = order.first.id;
    }
  });
}
