import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/utils/player_validation.dart';
import '../../../../core/utils/round_generator.dart';
import '../../../../services/ads/ads_service.dart';
import '../../ads/interstitial_policy.dart';
import '../../data/repositories/asset_word_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/game_settings.dart';
import '../../domain/entities/player.dart';
import '../../domain/enums/app_theme_mode.dart';
import '../../domain/enums/difficulty.dart';
import '../../domain/enums/game_phase.dart';
import '../../domain/repositories/word_repository.dart';
import 'game_session.dart';

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return AssetWordRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository?>((ref) {
  return null;
});

final gameControllerProvider =
    StateNotifierProvider<GameController, GameSession>((ref) {
      return GameController(
        wordRepository: ref.watch(wordRepositoryProvider),
        settingsRepository: ref.watch(settingsRepositoryProvider),
        adsService: ref.watch(adsServiceProvider),
      );
    });

class GameController extends StateNotifier<GameSession> {
  GameController({
    required WordRepository wordRepository,
    SettingsRepository? settingsRepository,
    RoundGenerator? roundGenerator,
    Uuid? uuid,
    AdsService? adsService,
    DateTime Function()? now,
  }) : _words = wordRepository,
       _settingsRepo = settingsRepository,
       _generator = roundGenerator ?? RoundGenerator(),
       _uuid = uuid ?? const Uuid(),
       _ads = adsService ?? FakeAdsService(),
       _now = now ?? DateTime.now,
       super(const GameSession());

  final WordRepository _words;
  final SettingsRepository? _settingsRepo;
  final RoundGenerator _generator;
  final Uuid _uuid;
  final AdsService _ads;
  final DateTime Function() _now;
  DateTime? _lastInterstitialAt;
  bool _startingNextRound = false;

  Future<void> bootstrap() async {
    final saved = _settingsRepo?.load() ?? GameSettings.defaults;
    state = state.copyWith(settings: saved);
    try {
      await _words.load();
      state = state.copyWith(
        wordsReady: true,
        clearError: true,
        phase: GamePhase.home,
      );
    } catch (_) {
      state = state.copyWith(
        wordsReady: false,
        errorMessage: 'Something went wrong loading the word pack.',
        phase: GamePhase.error,
      );
    }
  }

  Future<void> _persist(GameSettings settings) async {
    await _settingsRepo?.save(settings);
  }

  void goHome() {
    state = state.copyWith(
      phase: GamePhase.home,
      clearRound: true,
      currentPlayerIndex: 0,
      isCardRevealed: false,
      isHolding: false,
      privacyLocked: false,
      clearError: true,
    );
  }

  void openHowToPlay() {
    state = state.copyWith(phase: GamePhase.howToPlay);
  }

  void openSettings() {
    state = state.copyWith(phase: GamePhase.settings);
  }

  void startPlayerSetup() {
    state = state.copyWith(
      phase: GamePhase.playerSetup,
      clearRound: true,
      currentPlayerIndex: 0,
      isCardRevealed: false,
      privacyLocked: false,
    );
  }

  String? addPlayer(String rawName) {
    final capacity = PlayerValidation.canAdd(state.players);
    if (capacity != null) return capacity;
    final error = PlayerValidation.validateName(
      rawName,
      existing: state.players,
      allowDuplicates: state.settings.allowDuplicateNames,
    );
    if (error != null) return error;

    final player = Player(
      id: _uuid.v4(),
      name: rawName.trim(),
      position: state.players.length + 1,
    );
    final players = [...state.players, player];
    final max = GameConstants.maxImpostersFor(players.length);
    var settings = state.settings;
    if (max > 0 && settings.imposterCount > max) {
      settings = settings.copyWith(imposterCount: max);
    }
    state = state.copyWith(players: players, settings: settings);
    return null;
  }

  void removePlayer(String id) {
    final filtered = state.players.where((p) => p.id != id).toList();
    final reindexed = [
      for (var i = 0; i < filtered.length; i++)
        filtered[i].copyWith(position: i + 1),
    ];
    final max = GameConstants.maxImpostersFor(reindexed.length);
    var settings = state.settings;
    if (max > 0 && settings.imposterCount > max) {
      settings = settings.copyWith(imposterCount: max);
    }
    state = state.copyWith(players: reindexed, settings: settings);
  }

  void goToConfiguration() {
    final error = PlayerValidation.canContinue(state.players);
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return;
    }
    final max = GameConstants.maxImpostersFor(state.players.length);
    final settings = state.settings.copyWith(
      imposterCount: state.settings.imposterCount.clamp(1, max < 1 ? 1 : max),
    );
    state = state.copyWith(
      phase: GamePhase.configuration,
      settings: settings,
      clearError: true,
    );
  }

  void editPlayers() {
    state = state.copyWith(
      phase: GamePhase.playerSetup,
      clearRound: true,
      isCardRevealed: false,
    );
  }

  Future<void> setDifficulty(Difficulty difficulty) async {
    final settings = state.settings.copyWith(difficulty: difficulty);
    state = state.copyWith(settings: settings);
    await _persist(settings);
  }

  Future<void> setImposterCount(int count) async {
    final max = GameConstants.maxImpostersFor(state.players.length);
    final settings = state.settings.copyWith(
      imposterCount: count.clamp(1, max < 1 ? 1 : max),
    );
    state = state.copyWith(settings: settings);
    await _persist(settings);
  }

  Future<void> setShowHint(bool value) async {
    final settings = state.settings.copyWith(showHint: value);
    state = state.copyWith(settings: settings);
    await _persist(settings);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final settings = state.settings.copyWith(themeMode: mode);
    state = state.copyWith(settings: settings);
    await _persist(settings);
  }

  Future<void> setHapticEnabled(bool value) async {
    final settings = state.settings.copyWith(hapticEnabled: value);
    state = state.copyWith(settings: settings);
    await _persist(settings);
  }

  Future<void> setAnimationsEnabled(bool value) async {
    final settings = state.settings.copyWith(animationsEnabled: value);
    state = state.copyWith(settings: settings);
    await _persist(settings);
  }

  Future<void> setSoundEnabled(bool value) async {
    final settings = state.settings.copyWith(soundEnabled: value);
    state = state.copyWith(settings: settings);
    await _persist(settings);
  }

  Future<void> resetSettings() async {
    await _settingsRepo?.reset();
    state = state.copyWith(settings: GameSettings.defaults);
  }

  Future<void> startRound() async {
    if (!_words.isLoaded) {
      state = state.copyWith(
        errorMessage: 'Something went wrong loading the word pack.',
        phase: GamePhase.error,
      );
      return;
    }
    final setupError = PlayerValidation.canContinue(state.players);
    if (setupError != null) {
      state = state.copyWith(errorMessage: setupError);
      return;
    }
    try {
      final word = _words.randomWordForRound(state.settings.difficulty);
      final round = _generator.createRound(
        roundId: _uuid.v4(),
        players: state.players,
        secretWord: word,
        difficulty: state.settings.difficulty,
        imposterCount: state.settings.imposterCount,
        showHint: state.settings.showHint,
      );
      state = state.copyWith(
        phase: GamePhase.passPhone,
        round: round,
        currentPlayerIndex: 0,
        isCardRevealed: false,
        isHolding: false,
        privacyLocked: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        phase: GamePhase.configuration,
        errorMessage: 'Could not start the round. Try again.',
      );
    }
  }

  void confirmReadyToReveal() {
    state = state.copyWith(
      phase: GamePhase.readyToReveal,
      privacyLocked: false,
      isCardRevealed: false,
      isHolding: false,
    );
  }

  void beginHolding() {
    if (state.phase != GamePhase.readyToReveal &&
        state.phase != GamePhase.revealing) {
      return;
    }
    state = state.copyWith(phase: GamePhase.revealing, isHolding: true);
  }

  void cancelHolding() {
    if (state.isCardRevealed) return;
    state = state.copyWith(phase: GamePhase.readyToReveal, isHolding: false);
  }

  void revealCurrentPlayer() {
    state = state.copyWith(
      phase: GamePhase.revealed,
      isCardRevealed: true,
      isHolding: false,
    );
  }

  void passToNextPlayer() {
    if (state.isLastPlayer) {
      finishRevealPhase();
      return;
    }
    state = state.copyWith(
      currentPlayerIndex: state.currentPlayerIndex + 1,
      phase: GamePhase.passPhone,
      isCardRevealed: false,
      isHolding: false,
      privacyLocked: false,
    );
  }

  void finishRevealPhase() {
    state = state.copyWith(
      phase: GamePhase.allRevealed,
      isCardRevealed: false,
      isHolding: false,
    );
  }

  void showRoundReady() {
    final completed = state.phase == GamePhase.roundReady
        ? state.roundsCompleted
        : state.roundsCompleted + 1;
    state = state.copyWith(
      phase: GamePhase.roundReady,
      isCardRevealed: false,
      roundsCompleted: completed,
    );
  }

  /// Starts another round from the between-rounds screen.
  ///
  /// A frequency-capped interstitial may play first. It is never requested
  /// from the pass-the-phone reveal flow, and the next secret is dealt only
  /// after the ad has finished or been skipped.
  Future<void> startNextRound() async {
    if (_startingNextRound) return;
    _startingNextRound = true;
    try {
      final betweenRounds =
          state.phase == GamePhase.roundReady && !state.phase.isRevealFlow;
      if (betweenRounds &&
          InterstitialPolicy.shouldShow(
            fromNextRound: true,
            roundsPlayed: state.roundsCompleted,
            lastShownAt: _lastInterstitialAt,
            now: _now(),
          )) {
        final shown = await _ads.showInterstitial();
        if (shown) _lastInterstitialAt = _now();
      }
      await startRound();
    } finally {
      _startingNextRound = false;
    }
  }

  void exitRound() {
    state = state.copyWith(
      phase: GamePhase.configuration,
      clearRound: true,
      currentPlayerIndex: 0,
      isCardRevealed: false,
      isHolding: false,
      privacyLocked: false,
    );
  }

  void onAppObscured() {
    if (!state.phase.showsSecret && state.phase != GamePhase.readyToReveal) {
      return;
    }
    state = state.copyWith(
      privacyLocked: true,
      isCardRevealed: false,
      isHolding: false,
      phase: GamePhase.passPhone,
    );
  }

  void unlockPrivacy() {
    state = state.copyWith(
      privacyLocked: false,
      phase: GamePhase.passPhone,
      isCardRevealed: false,
    );
  }
}
