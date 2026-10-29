import 'package:equatable/equatable.dart';
import '../enums/role.dart';

class PlayerAssignment extends Equatable {
  const PlayerAssignment({
    required this.playerId,
    required this.role,
    this.word,
    this.hint,
  });
  final String playerId;
  final Role role;
  final String? word;
  final String? hint;
  bool get isImposter => role == Role.imposter;
  @override
  List<Object?> get props => [playerId, role, word, hint];
  @override
  String toString() =>
      'PlayerAssignment(playerId: $playerId, role: ${role.name})';
}
