import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/core/utils/round_generator.dart';
import 'package:imposter_game/features/imposter/data/repositories/asset_word_repository.dart';
import 'package:imposter_game/features/imposter/domain/entities/word_entry.dart';
import 'package:imposter_game/features/imposter/domain/enums/difficulty.dart';
import 'package:imposter_game/features/imposter/domain/enums/game_phase.dart';
import 'package:imposter_game/features/imposter/presentation/providers/game_controller.dart';
import 'package:imposter_game/services/ads/ads_service.dart';

void main() {
  test(
    'interstitial waits for every 4th Again tap and skips the reveal',
    () async {
      final ads = FakeAdsService(interstitialSucceeds: true);
      final words = AssetWordRepository(random: Random(1));
      words.seedForTests(const [
        WordEntry(
          id: 'easy_001',
          difficulty: Difficulty.easy,
          category: 'nature',
          word: 'Water',
          hint: 'Liquid',
          tags: ['nature'],
        ),
      ]);
      var clock = DateTime(2026, 1, 1, 12);
      final controller = GameController(
        wordRepository: words,
        adsService: ads,
        roundGenerator: RoundGenerator(random: Random(1)),
        now: () => clock,
      );

      controller.addPlayer('Ava');
      controller.addPlayer('Ben');
      controller.addPlayer('Cleo');
      controller.goToConfiguration();
      await controller.startRound();
      expect(controller.state.phase, GamePhase.passPhone);
      expect(ads.interstitialRequests, 0);

      await controller.startNextRound();
      expect(controller.state.phase.isRevealFlow, isTrue);
      expect(ads.interstitialRequests, 0);

      Future<void> finishToReady() async {
        var guard = 0;
        while (controller.state.phase != GamePhase.roundReady) {
          expect(guard, lessThan(20));
          guard++;
          switch (controller.state.phase) {
            case GamePhase.passPhone:
              controller.confirmReadyToReveal();
            case GamePhase.readyToReveal:
            case GamePhase.revealing:
              controller.revealCurrentPlayer();
            case GamePhase.revealed:
              controller.passToNextPlayer();
            case GamePhase.allRevealed:
              controller.showRoundReady();
            default:
              fail('unexpected phase ${controller.state.phase}');
          }
        }
      }

      Future<void> again({required int requests}) async {
        await finishToReady();
        await controller.startNextRound();
        expect(ads.interstitialRequests, requests);
        expect(controller.state.phase, GamePhase.passPhone);
      }

      await again(requests: 0);
      expect(controller.state.roundsCompleted, 1);
      await again(requests: 0);
      await again(requests: 0);
      await again(requests: 1);
      expect(controller.state.roundsCompleted, 4);

      clock = clock.add(const Duration(seconds: 30));
      await again(requests: 1);
      await again(requests: 1);
      await again(requests: 1);
      await again(requests: 1);
      expect(controller.state.roundsCompleted, 8);

      clock = clock.add(const Duration(seconds: 90));
      await again(requests: 1);
      await again(requests: 1);
      await again(requests: 1);
      await again(requests: 2);
      expect(controller.state.roundsCompleted, 12);
    },
  );
}
