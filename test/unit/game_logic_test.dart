import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/core/constants/game_constants.dart';
import 'package:imposter_game/core/utils/player_validation.dart';
import 'package:imposter_game/core/utils/round_generator.dart';
import 'package:imposter_game/core/utils/word_pack_validator.dart';
import 'package:imposter_game/features/imposter/domain/entities/player.dart';
import 'package:imposter_game/features/imposter/domain/entities/word_entry.dart';
import 'package:imposter_game/features/imposter/domain/enums/difficulty.dart';
import 'package:imposter_game/features/imposter/domain/enums/role.dart';

List<Player> makePlayers(int count) => [
      for (var i = 0; i < count; i++)
        Player(id: 'p$i', name: 'Player ${i + 1}', position: i + 1),
    ];

WordEntry sampleWord() => const WordEntry(
      id: 'easy_001',
      difficulty: Difficulty.easy,
      category: 'nature',
      word: 'Water',
      hint: 'Liquid',
      tags: ['nature'],
    );

void main() {
  group('GameConstants.maxImpostersFor', () {
    test('matches floor(players / 3) with protected seats', () {
      expect(GameConstants.maxImpostersFor(3), 1);
      expect(GameConstants.maxImpostersFor(5), 1);
      expect(GameConstants.maxImpostersFor(6), 2);
      expect(GameConstants.maxImpostersFor(9), 3);
      expect(GameConstants.maxImpostersFor(12), 4);
      expect(GameConstants.maxImpostersFor(20), 6);
    });
  });

  group('PlayerValidation', () {
    test('rejects empty and duplicate names', () {
      final existing = makePlayers(2);
      expect(PlayerValidation.validateName('', existing: existing), isNotNull);
      expect(
        PlayerValidation.validateName('Player 1', existing: existing),
        isNotNull,
      );
      expect(PlayerValidation.validateName('Ava', existing: existing), isNull);
    });

    test('enforces min and max players', () {
      expect(PlayerValidation.canContinue(makePlayers(2)), isNotNull);
      expect(PlayerValidation.canContinue(makePlayers(3)), isNull);
      expect(PlayerValidation.canAdd(makePlayers(20)), isNotNull);
    });
  });

  group('RoundGenerator', () {
    test('never selects position 1 or 2 as imposter', () {
      final generator = RoundGenerator(random: Random(42));
      for (var i = 0; i < 200; i++) {
        final round = generator.createRound(
          roundId: 'r$i',
          players: makePlayers(6),
          secretWord: sampleWord(),
          difficulty: Difficulty.easy,
          imposterCount: 2,
          showHint: false,
        );
        for (final id in round.imposterIds) {
          final p = round.players.firstWhere((e) => e.id == id);
          expect(p.position, greaterThan(2));
        }
      }
    });

    test('starting player is independent and always set', () {
      final generator = RoundGenerator(random: Random(7));
      final starters = <String>{};
      for (var i = 0; i < 50; i++) {
        final round = generator.createRound(
          roundId: 'r$i',
          players: makePlayers(5),
          secretWord: sampleWord(),
          difficulty: Difficulty.easy,
          imposterCount: 1,
          showHint: true,
        );
        expect(round.startingPlayerId, isNotEmpty);
        starters.add(round.startingPlayerId);
        final assignment = round.assignmentFor(round.imposterIds.first)!;
        expect(assignment.role, Role.imposter);
        expect(assignment.word, isNull);
        expect(assignment.hint, 'Liquid');
      }
      expect(starters.length, greaterThan(1));
    });

    test('civilians see the word; imposters never do', () {
      final round = RoundGenerator(random: Random(1)).createRound(
        roundId: 'r1',
        players: makePlayers(5),
        secretWord: sampleWord(),
        difficulty: Difficulty.easy,
        imposterCount: 1,
        showHint: false,
      );
      for (final p in round.players) {
        final a = round.assignmentFor(p.id)!;
        if (a.isImposter) {
          expect(a.word, isNull);
          expect(a.hint, isNull);
        } else {
          expect(a.word, 'Water');
        }
      }
    });
  });

  group('WordPackValidator', () {
    test('rejects hint equal to word', () {
      final entries = [
        for (var i = 0; i < 600; i++)
          WordEntry(
            id: 'w$i',
            difficulty: Difficulty.values[i % 3],
            category: 'x',
            word: 'Word$i',
            hint: i == 0 ? 'Word0' : 'Hint$i',
          ),
      ];
      expect(
        () => const WordPackValidator()
            .validate(entries, throwOnError: true),
        throwsA(isA<WordValidationException>()),
      );
    });
  });
}
