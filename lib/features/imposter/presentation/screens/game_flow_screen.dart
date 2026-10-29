import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/widgets/party_widgets.dart';
import '../../../../services/ads/ads_service.dart';
import '../../../../services/ads/banner_ad_slot.dart';
import '../../domain/enums/app_theme_mode.dart';
import '../../domain/enums/difficulty.dart';
import '../../domain/enums/game_phase.dart';
import '../providers/game_controller.dart';
import '../providers/game_session.dart';
import '../widgets/secret_reveal_card.dart';
import '../widgets/wood_sign.dart';

class GameFlowScreen extends ConsumerStatefulWidget {
  const GameFlowScreen({super.key});

  @override
  ConsumerState<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends ConsumerState<GameFlowScreen>
    with WidgetsBindingObserver {
  final _nameController = TextEditingController();
  String? _nameError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(gameControllerProvider.notifier).onAppObscured();
    }
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this round?'),
        content: const Text('Your secret cards are already assigned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('KEEP PLAYING'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('EXIT ROUND'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      ref.read(gameControllerProvider.notifier).exitRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameControllerProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);

    return PopScope(
      canPop: !session.phase.isRevealFlow,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && session.phase.isRevealFlow) {
          await _confirmExit();
        }
      },
      // These screens draw their own full-bleed artwork, so they skip the
      // padded scaffold.
      child:
          session.phase == GamePhase.home ||
              session.phase == GamePhase.playerSetup ||
              session.phase == GamePhase.configuration ||
              session.phase.isRevealFlow ||
              session.phase == GamePhase.allRevealed ||
              session.phase == GamePhase.roundReady
          ? _buildBody(session, ctrl)
          : PartyScaffold(child: _buildBody(session, ctrl)),
    );
  }

  Widget _buildBody(GameSession session, GameController ctrl) {
    final body = _phaseBody(session, ctrl);
    // Home menu and the between-rounds screen only. Reveal phases, including
    // pass-the-phone and the secret card, never get a banner.
    if (!session.phase.showsBanner) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: body),
        const BannerAdSlot(),
      ],
    );
  }

  Widget _phaseBody(GameSession session, GameController ctrl) {
    switch (session.phase) {
      case GamePhase.splash:
        return const Center(child: CircularProgressIndicator());
      case GamePhase.home:
        return _HomeView(
          onStart: ctrl.startPlayerSetup,
          onSettings: ctrl.openSettings,
          onHowTo: ctrl.openHowToPlay,
        );
      case GamePhase.howToPlay:
        return _HowToPlayView(onBack: ctrl.goHome);
      case GamePhase.playerSetup:
        return _PlayerSetupView(
          session: session,
          nameController: _nameController,
          nameError: _nameError,
          onChanged: () => setState(() => _nameError = null),
          onAdd: () {
            final err = ctrl.addPlayer(_nameController.text);
            setState(() => _nameError = err);
            if (err == null) _nameController.clear();
          },
          onRemove: ctrl.removePlayer,
          onContinue: ctrl.goToConfiguration,
          onBack: ctrl.goHome,
        );
      case GamePhase.configuration:
        return _ConfigurationView(session: session, ctrl: ctrl);
      case GamePhase.passPhone:
      case GamePhase.readyToReveal:
      case GamePhase.revealing:
      case GamePhase.revealed:
        return _RevealView(session: session, ctrl: ctrl);
      case GamePhase.allRevealed:
        return _AllRevealedView(onContinue: ctrl.showRoundReady);
      case GamePhase.roundReady:
        return _RoundReadyView(
          session: session,
          onNext: ctrl.startNextRound,
          onHome: ctrl.goHome,
        );
      case GamePhase.settings:
        return _SettingsView(session: session, ctrl: ctrl);
      case GamePhase.error:
        return _ErrorView(
          message: session.errorMessage,
          onRetry: ctrl.bootstrap,
        );
    }
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({
    required this.onStart,
    required this.onSettings,
    required this.onHowTo,
  });

  final VoidCallback onStart;
  final VoidCallback onSettings;
  final VoidCallback onHowTo;

  static const _background = 'assets/images/home_background.webp';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Artwork already contains the logo, tagline and characters.
          Image.asset(
            _background,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6EC6FF), Color(0xFFE8C48A)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CandyButton(
                    label: 'START GAME',
                    icon: Icons.play_arrow_rounded,
                    onPressed: onStart,
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: CandyButton(
                      label: 'HOW TO PLAY',
                      icon: Icons.menu_book_rounded,
                      style: CandyButtonStyle.secondary,
                      onPressed: onHowTo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: CandyButton(
                      label: 'SETTINGS',
                      icon: Icons.settings_rounded,
                      style: CandyButtonStyle.secondary,
                      onPressed: onSettings,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToPlayView extends StatelessWidget {
  const _HowToPlayView({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('ADD PLAYERS', "Enter everyone's name."),
      ('REVEAL', 'Pass the phone and secretly reveal your card.'),
      ('GIVE CLUES', 'Everyone describes the secret word.'),
      ('FIND THE IMPOSTER', 'Discuss and figure out who is bluffing.'),
      ('NEW ROUND', 'Start another round with one tap.'),
    ];
    final on = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Text('How to Play', style: AppTextStyles.title(on)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: steps.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${steps[i].$1}',
                    style: AppTextStyles.title(on),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[i].$2,
                    style: AppTextStyles.body(on.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ),
        PrimaryButton(label: 'GOT IT', onPressed: onBack),
      ],
    );
  }
}

class _PlayerSetupView extends StatelessWidget {
  const _PlayerSetupView({
    required this.session,
    required this.nameController,
    required this.nameError,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onContinue,
    required this.onBack,
  });

  final GameSession session;
  final TextEditingController nameController;
  final String? nameError;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final void Function(String id) onRemove;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  static const _avatarColors = [
    AppColors.brightViolet,
    AppColors.coral,
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    AppColors.electricBlue,
    Color(0xFF66BB6A),
  ];

  @override
  Widget build(BuildContext context) {
    final players = session.players;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    const ink = AppColors.deepPurple;

    return _SignboardScaffold(
      image: 'assets/images/players_background.webp',
      imageSize: const Size(857, 1835),
      artBottom: 385,
      onBack: onBack,
      children: [
        Center(
          child: _Pill(
            child: Text(
              GameConstants.bestWithLabel,
              style: AppTextStyles.label(ink),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _NameInput(
          controller: nameController,
          error: nameError,
          onChanged: onChanged,
          onAdd: onAdd,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: players.isEmpty
              ? Align(
                  alignment: const Alignment(0, -0.3),
                  child: _Pill(
                    child: Text(
                      'Add at least ${GameConstants.minPlayers} '
                      'players to start.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(ink),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: players.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = players[i];
                    return _PlayerTile(
                      initials: p.initials,
                      position: p.position,
                      name: p.name,
                      color: _avatarColors[i % _avatarColors.length],
                      onRemove: () => onRemove(p.id),
                    );
                  },
                ),
        ),
        if (!keyboardOpen) ...[
          Center(
            child: _Pill(
              child: Text(
                '${players.length} / ${GameConstants.maxPlayers} players',
                style: AppTextStyles.label(ink),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CandyButton(
            label: 'CONTINUE',
            icon: Icons.arrow_forward_rounded,
            onPressed: players.length >= GameConstants.minPlayers
                ? onContinue
                : null,
          ),
        ],
      ],
    );
  }
}

/// Full-bleed scene artwork with a title sign baked into its top, an optional
/// floating back button, and content laid out below the artwork.
class _SignboardScaffold extends StatelessWidget {
  const _SignboardScaffold({
    required this.image,
    required this.imageSize,
    required this.artBottom,
    this.onBack,
    required this.children,
  });

  final String image;
  final Size imageSize;

  /// Bottom edge of the baked-in artwork (sign, illustrations), in image
  /// pixels. Content starts below it.
  final double artBottom;
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    // Push content below wherever BoxFit.cover (top-aligned) draws the art.
    final scale = math.max(
      media.size.width / imageSize.width,
      media.size.height / imageSize.height,
    );
    final contentTop = math.max(
      artBottom * scale + 8 - media.padding.top,
      onBack == null ? 0.0 : 56.0,
    );

    return Scaffold(
      // Keep the artwork fixed when the keyboard opens; content pads itself.
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            image,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6EC6FF), Color(0xFF8BD66B)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + keyboard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: keyboard > 0 && onBack != null ? 56 : contentTop,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: onBack == null
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _RoundIconButton(
                                icon: Icons.arrow_back_rounded,
                                onPressed: onBack!,
                              ),
                            ),
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted white pill used for small labels over the artwork.
class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.deepPurple),
      ),
    );
  }
}

class _NameInput extends StatelessWidget {
  const _NameInput({
    required this.controller,
    required this.error,
    required this.onChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.deepPurple;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: error != null ? AppColors.imposter : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brightViolet.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => onAdd(),
                  maxLength: GameConstants.maxNameLength,
                  style: AppTextStyles.title(ink),
                  cursorColor: AppColors.brightViolet,
                  decoration: InputDecoration(
                    hintText: 'Player name',
                    hintStyle: AppTextStyles.title(ink.withValues(alpha: 0.35)),
                    counterText: '',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Material(
                color: AppColors.brightViolet,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onAdd,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: _Pill(
                child: Text(
                  error!,
                  style: AppTextStyles.label(AppColors.imposter),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.initials,
    required this.position,
    required this.name,
    required this.color,
    required this.onRemove,
  });

  final String initials;
  final int position;
  final String name;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.deepPurple;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(initials, style: AppTextStyles.label(Colors.white)),
          ),
          const SizedBox(width: 12),
          Text(
            position.toString().padLeft(2, '0'),
            style: AppTextStyles.label(ink.withValues(alpha: 0.45)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.title(ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, color: ink.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _ConfigurationView extends StatelessWidget {
  const _ConfigurationView({required this.session, required this.ctrl});

  final GameSession session;
  final GameController ctrl;

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.deepPurple;
    final settings = session.settings;
    final playerCount = session.players.length;
    final maxImp = GameConstants.maxImpostersFor(playerCount);
    final count = settings.imposterCount;

    return _SignboardScaffold(
      image: 'assets/images/ready_background.webp',
      imageSize: const Size(866, 1815),
      artBottom: 445,
      onBack: ctrl.editPlayers,
      children: [
        Center(
          child: _Pill(
            color: const Color(0xFFE3F4FF).withValues(alpha: 0.9),
            child: Text(
              'Set the rules for this round.',
              style: AppTextStyles.title(
                const Color(0xFF1F4E9C),
              ).copyWith(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Difficulty',
                    style: AppTextStyles.title(ink).copyWith(
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.white70, blurRadius: 8),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final d in Difficulty.values) ...[
                      if (d != Difficulty.values.first)
                        const SizedBox(width: 8),
                      Expanded(
                        child: _DifficultyTile(
                          difficulty: d,
                          selected: settings.difficulty == d,
                          onTap: () => ctrl.setDifficulty(d),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _SettingCard(
                  emoji: '🕵️',
                  title: 'Imposters',
                  subtitle: 'Maximum for $playerCount players: $maxImp',
                  trailing: _Stepper(
                    value: count,
                    onMinus: count > 1
                        ? () => ctrl.setImposterCount(count - 1)
                        : null,
                    onPlus: count < maxImp
                        ? () => ctrl.setImposterCount(count + 1)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                _SettingCard(
                  emoji: '💡',
                  title: 'Show hint to imposter',
                  subtitle: 'A tiny clue — never the word itself.',
                  onTap: () => ctrl.setShowHint(!settings.showHint),
                  trailing: Switch(
                    value: settings.showHint,
                    onChanged: ctrl.setShowHint,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.brightViolet,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFF8E8AA3),
                    trackOutlineColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        CandyButton(
          label: 'EDIT PLAYERS',
          icon: Icons.groups_rounded,
          style: CandyButtonStyle.cream,
          onPressed: ctrl.editPlayers,
        ),
        const SizedBox(height: 12),
        CandyButton(
          label: 'CONTINUE',
          icon: Icons.casino_rounded,
          onPressed: ctrl.startRound,
        ),
      ],
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (fill, dot, accent) = switch (difficulty) {
      Difficulty.easy => (
        const Color(0xFFE6FBEF),
        const Color(0xFF22C55E),
        const Color(0xFF34C77B),
      ),
      Difficulty.medium => (
        const Color(0xFFFFF6E2),
        const Color(0xFFFFC107),
        const Color(0xFFF2B51C),
      ),
      Difficulty.hard => (
        const Color(0xFFFFEAEA),
        const Color(0xFFE53935),
        const Color(0xFFE85A5A),
      ),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: '${difficulty.label} difficulty',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : Colors.white,
              width: selected ? 2.5 : 2,
            ),
            boxShadow: [
              // Chunky bottom edge, like the candy buttons.
              BoxShadow(
                color: selected
                    ? accent.withValues(alpha: 0.55)
                    : const Color(0xFFD9CFC4),
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 20, color: accent),
                  const SizedBox(width: 4),
                ],
                _GlossyDot(color: dot),
                const SizedBox(width: 8),
                Text(
                  difficulty.label,
                  style: AppTextStyles.title(
                    const Color(0xFF4A2A1A),
                  ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlossyDot extends StatelessWidget {
  const _GlossyDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [Color.lerp(color, Colors.white, 0.45)!, color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Cream card with a chunky bottom edge, an emoji badge and a control.
class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.deepPurple;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EE),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            const BoxShadow(color: Color(0xFFE6D8C6), offset: Offset(0, 5)),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF1D6), Color(0xFFFCE1B8)],
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFEBCB9C), offset: Offset(0, 3)),
                ],
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.title(
                      ink,
                    ).copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.body(
                      ink.withValues(alpha: 0.6),
                    ).copyWith(fontSize: 15, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECF7),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onPressed: onMinus,
            filled: false,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.headline(
                AppColors.deepPurple,
              ).copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onPressed: onPlus,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
    required this.filled,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = filled ? AppColors.brightViolet : const Color(0xFFD9CCFF);
    final fg = filled ? Colors.white : AppColors.brightViolet;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        elevation: enabled && filled ? 2 : 0,
        shadowColor: AppColors.brightViolet,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: fg, size: 24),
          ),
        ),
      ),
    );
  }
}

class _RevealView extends StatelessWidget {
  const _RevealView({required this.session, required this.ctrl});

  final GameSession session;
  final GameController ctrl;

  /// Whether the "pass the phone" hand-off screen is showing, rather than the
  /// secret card.
  static bool showsPassPhone(GameSession session) =>
      session.phase.isRevealFlow &&
      session.currentPlayer != null &&
      (session.privacyLocked || session.phase == GamePhase.passPhone);

  @override
  Widget build(BuildContext context) {
    final player = session.currentPlayer;
    if (player == null) return const SizedBox.shrink();
    final haptics = HapticService(enabled: session.settings.hapticEnabled);

    if (showsPassPhone(session)) {
      return _PassPhoneView(
        playerId: player.id,
        playerName: player.name,
        privacyLocked: session.privacyLocked,
        animate: session.settings.animationsEnabled,
        onReady: session.privacyLocked
            ? ctrl.unlockPrivacy
            : ctrl.confirmReadyToReveal,
      );
    }

    final assignment = session.currentAssignment;
    if (assignment == null) return const SizedBox.shrink();
    final revealed = session.isCardRevealed;

    return _SignboardScaffold(
      image: 'assets/images/your_turn_background.webp',
      imageSize: const Size(886, 1776),
      artBottom: 0,
      children: [
        const SizedBox(height: 28),
        WoodSign(line1: 'Your turn,', line2: '${player.name} 👀'),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SparkBurst(),
            const SizedBox(width: 8),
            Flexible(
              child: _Pill(
                color: const Color(0xFFD9F1FF).withValues(alpha: 0.95),
                child: Text(
                  revealed ? 'Keep this secret 🤫' : 'Hold to reveal',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title(
                    const Color(0xFF1F4E9C),
                  ).copyWith(fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const SparkBurst(mirrored: true),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              // Portrait card, as big as fits (with room for the glow).
              final w = math.min(
                box.maxWidth * 0.8,
                (box.maxHeight - 16) / 1.2,
              );
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: w,
                  child: SecretRevealCard(
                    playerName: player.name,
                    assignment: assignment,
                    isRevealed: revealed,
                    onReveal: ctrl.revealCurrentPlayer,
                    haptics: haptics,
                    animationsEnabled: session.settings.animationsEnabled,
                    height: w * 1.2,
                  ),
                ),
              );
            },
          ),
        ),
        if (revealed) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CandyButton(
              label: session.isLastPlayer ? 'START GAME' : 'PASS TO NEXT',
              icon: session.isLastPlayer ? Icons.play_arrow_rounded : null,
              trailingIcon: session.isLastPlayer
                  ? null
                  : Icons.arrow_forward_rounded,
              onPressed: session.isLastPlayer
                  ? ctrl.finishRevealPhase
                  : ctrl.passToNextPlayer,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PassPhoneView extends StatelessWidget {
  const _PassPhoneView({
    required this.playerId,
    required this.playerName,
    required this.privacyLocked,
    required this.animate,
    required this.onReady,
  });

  final String playerId;
  final String playerName;
  final bool privacyLocked;
  final bool animate;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.deepPurple;
    Widget card = _StitchedCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            privacyLocked ? 'Screen hidden for privacy.' : 'Give the phone to',
            textAlign: TextAlign.center,
            style: AppTextStyles.title(
              ink,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SparkBurst(),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _BigName(playerName.toUpperCase()),
                ),
              ),
              const SizedBox(width: 10),
              const SparkBurst(mirrored: true),
            ],
          ),
          const SizedBox(height: 10),
          _Pill(
            color: const Color(0xFFE6DEFF),
            child: Text(
              privacyLocked
                  ? "Let's continue safely 🔒"
                  : 'Only $playerName should look 👀',
              textAlign: TextAlign.center,
              style: AppTextStyles.label(ink).copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );
    if (animate) {
      card = card
          .animate(key: ValueKey(playerId))
          .fadeIn(duration: 250.ms)
          .scale(
            begin: const Offset(0.85, 0.85),
            duration: 500.ms,
            curve: Curves.elasticOut,
          );
    }

    return _SignboardScaffold(
      image: 'assets/images/pass_phone_background.webp',
      imageSize: const Size(867, 1815),
      // Below the paws handing over the phone.
      artBottom: 1020,
      children: [
        Expanded(
          child: Align(
            alignment: const Alignment(0, -0.4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 64,
                  child: card,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CandyButton(
            label: "I'M READY",
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: onReady,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Cream card with a dashed "stitched" inner border.
class _StitchedCard extends StatelessWidget {
  const _StitchedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          const BoxShadow(color: Color(0xFFE6D8C6), offset: Offset(0, 5)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFD8C8B2),
          radius: AppRadii.lg - 8,
          inset: 8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.inset,
  });

  final Color color;
  final double radius;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(inset),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const dash = 7.0, gap = 6.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius || old.inset != inset;
}

/// Chunky violet name with a white outline, like the game's title lettering.
class _BigName extends StatelessWidget {
  const _BigName(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 64,
      fontWeight: FontWeight.w900,
      height: 1.1,
      letterSpacing: 1,
    );
    return Stack(
      children: [
        // White outline with a soft violet drop shadow.
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
            shadows: [
              Shadow(
                color: AppColors.brightViolet.withValues(alpha: 0.35),
                offset: const Offset(0, 4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9B6BFF), Color(0xFF5B21D6)],
          ).createShader(bounds),
          child: Text(text, style: style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}

class _AllRevealedView extends StatelessWidget {
  const _AllRevealedView({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return _SignboardScaffold(
      image: 'assets/images/your_turn_background.webp',
      imageSize: const Size(886, 1776),
      artBottom: 0,
      children: [
        // The sign hangs a little way down, on long ropes.
        SizedBox(height: height * 0.12),
        const WoodSign(line1: 'Everyone', line2: 'has seen\ntheir role.'),
        const SizedBox(height: 18),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SparkBurst(),
            SizedBox(width: 8),
            Flexible(child: _StitchedPill(text: 'Time to find the imposter.')),
            SizedBox(width: 8),
            SparkBurst(mirrored: true),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CandyButton(
            label: 'START GAME',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        ),
        SizedBox(height: height * 0.06),
      ],
    );
  }
}

/// Small cream label with a dashed "stitched" edge. Shrinks to fit; use
/// line breaks in [text] for multiple lines.
class _StitchedPill extends StatelessWidget {
  const _StitchedPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          const BoxShadow(color: Color(0xFFE6D8C6), offset: Offset(0, 4)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: const _DashedBorderPainter(
          color: Color(0xFFD8C8B2),
          radius: AppRadii.md - 5,
          inset: 5,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.title(
                AppColors.deepPurple,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundReadyView extends StatelessWidget {
  const _RoundReadyView({
    required this.session,
    required this.onNext,
    required this.onHome,
  });

  final GameSession session;
  final VoidCallback onNext;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final starter = session.startingPlayer;
    final size = MediaQuery.of(context).size;
    return _SignboardScaffold(
      image: 'assets/images/round_background.webp',
      imageSize: const Size(871, 1805),
      artBottom: 0,
      children: [
        Expanded(
          // Everything above the buttons shrinks together on short screens.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: size.width - 40,
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.02),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SparkBurst(),
                      SizedBox(width: 10),
                      Text('🎉', style: TextStyle(fontSize: 56)),
                      SizedBox(width: 10),
                      SparkBurst(mirrored: true),
                    ],
                  ),
                  const WoodSign(
                    line1: "EVERYONE'S READY",
                    line2: 'THE ROUND\nBEGINS NOW',
                    line1Size: 26,
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SparkBurst(),
                      SizedBox(width: 8),
                      Flexible(
                        child: _StitchedPill(
                          text:
                              'Give clues. Listen carefully.\n'
                              'Find the imposter.',
                        ),
                      ),
                      SizedBox(width: 8),
                      SparkBurst(mirrored: true),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _StarterCard(name: starter?.name ?? '?'),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: WoodBanner(
                      text: 'Put the phone down and start talking!',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CandyButton(label: 'AGAIN! 🔥', onPressed: onNext),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CandyButton(
            label: 'HOME',
            style: CandyButtonStyle.secondary,
            onPressed: onHome,
          ),
        ),
        SizedBox(height: size.height * 0.02),
      ],
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          const BoxShadow(color: Color(0xFFE6D8C6), offset: Offset(0, 6)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'STARTING PLAYER',
            style: AppTextStyles.label(const Color(0xFFF2A516)).copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SparkBurst(),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '🗣️ $name starts!',
                    maxLines: 1,
                    style: AppTextStyles.display(
                      AppColors.deepPurple,
                    ).copyWith(fontSize: 38),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const SparkBurst(mirrored: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({required this.session, required this.ctrl});

  final GameSession session;
  final GameController ctrl;

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    final s = session.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: ctrl.goHome,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Text('Settings', style: AppTextStyles.title(on)),
          ],
        ),
        Expanded(
          child: ListView(
            children: [
              Text(
                'APPEARANCE',
                style: AppTextStyles.label(on.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 8),
              GlowCard(
                child: Wrap(
                  spacing: 8,
                  children: AppThemeMode.values.map((m) {
                    return ChoiceChip(
                      label: Text(m.label),
                      selected: s.themeMode == m,
                      onSelected: (_) => ctrl.setThemeMode(m),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'GAMEPLAY',
                style: AppTextStyles.label(on.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 8),
              GlowCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Haptic feedback'),
                      value: s.hapticEnabled,
                      onChanged: ctrl.setHapticEnabled,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Animations'),
                      value: s.animationsEnabled,
                      onChanged: ctrl.setAnimationsEnabled,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sound effects'),
                      value: s.soundEnabled,
                      onChanged: ctrl.setSoundEnabled,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _AdPrivacySection(),
              SecondaryButton(
                label: 'RESET SETTINGS',
                onPressed: ctrl.resetSettings,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'HOW TO PLAY',
                onPressed: ctrl.openHowToPlay,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown only when UMP requires a privacy-options entry point.
class _AdPrivacySection extends ConsumerStatefulWidget {
  const _AdPrivacySection();

  @override
  ConsumerState<_AdPrivacySection> createState() => _AdPrivacySectionState();
}

class _AdPrivacySectionState extends ConsumerState<_AdPrivacySection> {
  late final Future<bool> _required;

  @override
  void initState() {
    super.initState();
    _required = ref.read(adsServiceProvider).privacyOptionsRequired;
  }

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    return FutureBuilder<bool>(
      future: _required,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ADS', style: AppTextStyles.label(on.withValues(alpha: 0.55))),
            const SizedBox(height: 8),
            GlowCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ad privacy choices'),
                subtitle: const Text('Manage how ads are personalized'),
                onTap: () {
                  ref.read(adsServiceProvider).showPrivacyOptions();
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.error_outline, size: 64, color: AppColors.imposter),
        const SizedBox(height: 12),
        Text(
          message ?? 'Something went wrong loading the word pack.',
          textAlign: TextAlign.center,
          style: AppTextStyles.title(Theme.of(context).colorScheme.onSurface),
        ),
        const Spacer(),
        PrimaryButton(label: 'TRY AGAIN', onPressed: onRetry),
      ],
    );
  }
}
