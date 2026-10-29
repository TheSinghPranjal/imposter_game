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

  int clampImposterCount(int requested, int playerCount) {
    final max = GameConstants.maxImpostersFor(playerCount);
    if (max <= 0) return 0;
    return requested.clamp(1, max);
  }

  /// The players in the order they were added, rotated to start from a random
  /// player. The rotation never starts from [previousFirstId] again, so every
  /// new game begins with someone different.
  List<Player> revealOrder(List<Player> players, {String? previousFirstId}) {
    final sorted = [...players]
      ..sort((a, b) => a.position.compareTo(b.position));
    if (sorted.length < 2) return sorted;
    final starts = [
      for (var i = 0; i < sorted.length; i++)
        if (sorted[i].id != previousFirstId) i,
    ];
    final start = starts[_random.nextInt(starts.length)];
    return [...sorted.skip(start), ...sorted.take(start)];
  }

  /// Picks imposters from [order]. When [protectFirst] is set, the first
  /// player in the reveal order is never chosen.
  List<String> selectImposterIds({
    required List<Player> order,
    required int imposterCount,
    required bool protectFirst,
  }) {
    final eligible = protectFirst
        ? order.skip(GameConstants.protectedPositions).toList()
        : [...order];
    final count = clampImposterCount(imposterCount, order.length);
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
    bool protectFirstPlayer = true,
    String? previousFirstPlayerId,
  }) {
    final order = revealOrder(players, previousFirstId: previousFirstPlayerId);
    final imposters = selectImposterIds(
      order: order,
      imposterCount: imposterCount,
      protectFirst: protectFirstPlayer,
    );
    final assignments = buildAssignments(
      players: order,
      imposterIds: imposters,
      secretWord: secretWord,
      showHint: showHint,
    );
    return Round(
      id: roundId,
      secretWord: secretWord,
      difficulty: difficulty,
      players: List.unmodifiable(order),
      assignments: Map.unmodifiable(assignments),
      imposterIds: List.unmodifiable(imposters),
      startingPlayerId: selectStartingPlayerId(order),
      createdAt: DateTime.now(),
    );
  }

  /// Same round, same imposters, new secret word for everyone.
  Round replaceWord(
    Round round, {
    required WordEntry secretWord,
    required bool showHint,
  }) {
    final assignments = buildAssignments(
      players: round.players,
      imposterIds: round.imposterIds,
      secretWord: secretWord,
      showHint: showHint,
    );
    return Round(
      id: round.id,
      secretWord: secretWord,
      difficulty: secretWord.difficulty,
      players: round.players,
      assignments: Map.unmodifiable(assignments),
      imposterIds: round.imposterIds,
      startingPlayerId: round.startingPlayerId,
      createdAt: round.createdAt,
    );
  }
}
