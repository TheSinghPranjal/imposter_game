import 'dart:math';

import '../../features/imposter/domain/entities/player.dart';
import '../../features/imposter/domain/entities/player_assignment.dart';
import '../../features/imposter/domain/entities/round.dart';
import '../../features/imposter/domain/entities/word_entry.dart';
import '../../features/imposter/domain/enums/difficulty.dart';
import '../../features/imposter/domain/enums/role.dart';
import '../constants/game_constants.dart';

class RoundGenerator {
  RoundGenerator({Random? random}) : _random = random ?? Random();
  final Random _random;

  List<int> eligibleImposterPositions(int playerCount) {
    if (playerCount < GameConstants.minPlayers) return const [];
    return [
      for (var i = GameConstants.protectedPositions + 1; i <= playerCount; i++)
        i,
    ];
  }

  int clampImposterCount(int requested, int playerCount) {
    final max = GameConstants.maxImpostersFor(playerCount);
    if (max <= 0) return 0;
    return requested.clamp(1, max);
  }

  List<String> selectImposterIds({
    required List<Player> players,
    required int imposterCount,
  }) {
    final sorted = [...players]
      ..sort((a, b) => a.position.compareTo(b.position));
    final eligible = sorted
        .where((p) => p.position > GameConstants.protectedPositions)
        .toList();
    final count = clampImposterCount(imposterCount, players.length);
    if (count > eligible.length) {
      throw StateError('Not enough eligible imposter positions.');
    }
    final pool = [...eligible]..shuffle(_random);
    return pool.take(count).map((p) => p.id).toList();
  }

  String selectStartingPlayerId(List<Player> players) {
    if (players.isEmpty) throw StateError('No players');
    return players[_random.nextInt(players.length)].id;
  }

  Map<String, PlayerAssignment> buildAssignments({
    required List<Player> players,
    required List<String> imposterIds,
    required WordEntry secretWord,
    required bool showHint,
  }) {
    final set = imposterIds.toSet();
    return {
      for (final p in players)
        p.id: PlayerAssignment(
          playerId: p.id,
          role: set.contains(p.id) ? Role.imposter : Role.civilian,
          word: set.contains(p.id) ? null : secretWord.word,
          hint: set.contains(p.id) && showHint ? secretWord.hint : null,
        ),
    };
  }

  Round createRound({
    required String roundId,
    required List<Player> players,
    required WordEntry secretWord,
    required Difficulty difficulty,
    required int imposterCount,
    required bool showHint,
  }) {
    final imposters = selectImposterIds(
      players: players,
      imposterCount: imposterCount,
    );
    final assignments = buildAssignments(
      players: players,
      imposterIds: imposters,
      secretWord: secretWord,
      showHint: showHint,
    );
    return Round(
      id: roundId,
      secretWord: secretWord,
      difficulty: difficulty,
      players: List.unmodifiable(players),
      assignments: Map.unmodifiable(assignments),
      imposterIds: List.unmodifiable(imposters),
      startingPlayerId: selectStartingPlayerId(players),
      createdAt: DateTime.now(),
    );
  }
}
