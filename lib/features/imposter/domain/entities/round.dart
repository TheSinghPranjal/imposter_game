import 'package:equatable/equatable.dart';
import '../enums/difficulty.dart';
import 'player.dart';
import 'player_assignment.dart';
import 'word_entry.dart';

class Round extends Equatable {
  const Round({
    required this.id,
    required this.secretWord,
    required this.difficulty,
    required this.players,
    required this.assignments,
    required this.imposterIds,
    required this.startingPlayerId,
    required this.createdAt,
  });
  final String id;
  final WordEntry secretWord;
  final Difficulty difficulty;
  final List<Player> players;
  final Map<String, PlayerAssignment> assignments;
  final List<String> imposterIds;
  final String startingPlayerId;
  final DateTime createdAt;
  PlayerAssignment? assignmentFor(String playerId) => assignments[playerId];
  Player? get startingPlayer {
    for (final p in players) {
      if (p.id == startingPlayerId) return p;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    secretWord.id,
    difficulty,
    players,
    assignments,
    imposterIds,
    startingPlayerId,
    createdAt,
  ];
  @override
  String toString() => 'Round(id: $id, players: ${players.length})';
}
