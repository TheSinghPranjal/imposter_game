import 'package:equatable/equatable.dart';

import '../../domain/entities/game_settings.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/player_assignment.dart';
import '../../domain/entities/round.dart';
import '../../domain/enums/game_phase.dart';

class GameSession extends Equatable {
  const GameSession({
    this.phase = GamePhase.splash,
    this.players = const [],
    this.settings = GameSettings.defaults,
    this.round,
    this.currentPlayerIndex = 0,
    this.isCardRevealed = false,
    this.isHolding = false,
    this.privacyLocked = false,
    this.errorMessage,
    this.wordsReady = false,
    this.roundsCompleted = 0,
  });

  final GamePhase phase;
  final List<Player> players;
  final GameSettings settings;
  final Round? round;
  final int currentPlayerIndex;
  final bool isCardRevealed;
  final bool isHolding;
  final bool privacyLocked;
  final String? errorMessage;
  final bool wordsReady;

  /// Rounds that reached the between-rounds screen in this session.
  final int roundsCompleted;

  Player? get currentPlayer {
    if (players.isEmpty) return null;
    if (currentPlayerIndex < 0 || currentPlayerIndex >= players.length) {
      return null;
    }
    return players[currentPlayerIndex];
  }

  PlayerAssignment? get currentAssignment {
    final p = currentPlayer;
    final r = round;
    if (p == null || r == null) return null;
    return r.assignmentFor(p.id);
  }

  bool get isLastPlayer =>
      players.isNotEmpty && currentPlayerIndex >= players.length - 1;

  Player? get startingPlayer => round?.startingPlayer;

  GameSession copyWith({
    GamePhase? phase,
    List<Player>? players,
    GameSettings? settings,
    Round? round,
    bool clearRound = false,
    int? currentPlayerIndex,
    bool? isCardRevealed,
    bool? isHolding,
    bool? privacyLocked,
    String? errorMessage,
    bool clearError = false,
    bool? wordsReady,
    int? roundsCompleted,
  }) {
    return GameSession(
      phase: phase ?? this.phase,
      players: players ?? this.players,
      settings: settings ?? this.settings,
      round: clearRound ? null : (round ?? this.round),
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      isCardRevealed: isCardRevealed ?? this.isCardRevealed,
      isHolding: isHolding ?? this.isHolding,
      privacyLocked: privacyLocked ?? this.privacyLocked,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      wordsReady: wordsReady ?? this.wordsReady,
      roundsCompleted: roundsCompleted ?? this.roundsCompleted,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    players,
    settings,
    round?.id,
    currentPlayerIndex,
    isCardRevealed,
    isHolding,
    privacyLocked,
    errorMessage,
    wordsReady,
    roundsCompleted,
  ];
}
