import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/widgets/party_widgets.dart';
import '../../domain/entities/player_assignment.dart';

class SecretRevealCard extends StatefulWidget {
  const SecretRevealCard({
    super.key,
    required this.playerName,
    required this.assignment,
    required this.isRevealed,
    required this.onReveal,
    required this.haptics,
    this.animationsEnabled = true,
    this.height = 320,
  });

  final String playerName;
  final PlayerAssignment assignment;
  final bool isRevealed;
  final VoidCallback onReveal;
  final HapticService haptics;
  final bool animationsEnabled;
  final double height;

  @override
  State<SecretRevealCard> createState() => _SecretRevealCardState();
}

class _SecretRevealCardState extends State<SecretRevealCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  double _progress = 0;
  bool _holding = false;
  bool _midDone = false;
  DateTime? _started;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    if (widget.isRevealed) _flip.value = 1;
  }

  @override
  void didUpdateWidget(covariant SecretRevealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _flip.forward();
    } else if (!widget.isRevealed && oldWidget.isRevealed) {
      _flip.reverse();
      _progress = 0;
      _holding = false;
      _midDone = false;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  Future<void> _startHold() async {
    if (widget.isRevealed) return;
    setState(() {
      _holding = true;
      _progress = 0;
      _midDone = false;
      _started = DateTime.now();
    });
    await widget.haptics.light();
    _tick();
  }

  void _tick() {
    if (!_holding || !mounted || widget.isRevealed) return;
    final started = _started;
    if (started == null) return;
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    final p = (elapsed / GameConstants.holdToRevealMs).clamp(0.0, 1.0);
    setState(() => _progress = p);
    if (!_midDone && p >= 0.5) {
      _midDone = true;
      widget.haptics.selection();
    }
    if (p >= 1) {
      _complete();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 16), _tick);
  }

  Future<void> _complete() async {
    _holding = false;
    await widget.haptics.medium();
    widget.onReveal();
    if (widget.animationsEnabled) {
      await _flip.forward();
    } else {
      _flip.value = 1;
    }
  }

  void _endHold() {
    if (widget.isRevealed) return;
    setState(() {
      _holding = false;
      _progress = 0;
      _midDone = false;
    });
  }

  Future<void> _a11y() async {
    if (widget.isRevealed) return;
    await widget.haptics.medium();
    widget.onReveal();
    if (widget.animationsEnabled) {
      await _flip.forward();
    } else {
      _flip.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a11y = MediaQuery.maybeOf(context)?.accessibleNavigation == true;
    return Semantics(
      label: widget.isRevealed
          ? 'Secret revealed for ${widget.playerName}'
          : 'Secret card for ${widget.playerName}. Press and hold to reveal.',
      button: true,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _flip,
            builder: (context, _) {
              final angle = _flip.value * math.pi;
              final showBack = angle >= math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                child: showBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _Face(
                          height: widget.height,
                          progress: 0,
                          colors: widget.assignment.isImposter
                              ? const [Color(0xFFFF5A6E), Color(0xFFB0132B)]
                              : const [Color(0xFF5A8CFF), Color(0xFF2D3FC4)],
                          rim: widget.assignment.isImposter
                              ? const Color(0xFFFFB3BE)
                              : const Color(0xFFB9CCFF),
                          child: _Revealed(assignment: widget.assignment),
                        ),
                      )
                    : GestureDetector(
                        onLongPressStart: (_) => _startHold(),
                        onLongPressEnd: (_) => _endHold(),
                        onLongPressCancel: _endHold,
                        child: _Face(
                          height: widget.height,
                          progress: _progress,
                          child: _Hidden(pressed: _holding),
                        ),
                      ),
              );
            },
          ),
          if (a11y && !widget.isRevealed) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _a11y,
              child: const Text('Tap to reveal (accessibility)'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.child,
    required this.progress,
    required this.height,
    this.colors = const [Color(0xFF8A4DFF), Color(0xFF5B21D6)],
    this.rim = const Color(0xFFCDB6FF),
  });

  final Widget child;
  final double progress;
  final double height;
  final List<Color> colors;
  final Color rim;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.lg + 4);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: rim, width: 3),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.9),
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.55),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [const _CardDecor(), child],
              ),
            ),
          ),
          if (progress > 0)
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                color: AppColors.warmYellow,
                backgroundColor: Colors.white24,
              ),
            ),
        ],
      ),
    );
  }
}

/// Glossy diagonal sheen plus faint "?" and star doodles.
class _CardDecor extends StatelessWidget {
  const _CardDecor();

  @override
  Widget build(BuildContext context) {
    Widget doodle(Alignment at, Widget child) =>
        Align(alignment: at, child: child);
    const faint = Color(0x26FFFFFF);
    Widget mark(double size) => Text(
      '?',
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: faint,
      ),
    );
    Widget star(double size) =>
        Icon(Icons.star_rounded, size: size, color: faint);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Diagonal glossy bands.
          Transform.rotate(
            angle: -0.75,
            child: FractionallySizedBox(
              widthFactor: 2,
              child: Align(
                alignment: const Alignment(0, -0.35),
                child: Container(
                  height: 70,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.75,
            child: FractionallySizedBox(
              widthFactor: 2,
              child: Align(
                alignment: const Alignment(0, 0.55),
                child: Container(
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          doodle(const Alignment(-0.82, -0.8), mark(58)),
          doodle(const Alignment(0.8, -0.78), star(56)),
          doodle(const Alignment(0.55, -0.4), star(28)),
          doodle(const Alignment(-0.85, 0.05), star(30)),
          doodle(const Alignment(0.85, 0.02), star(30)),
          doodle(const Alignment(-0.8, 0.85), mark(64)),
          doodle(const Alignment(0.8, 0.85), mark(58)),
          doodle(const Alignment(0, 0.93), star(34)),
        ],
      ),
    );
  }
}

class _Hidden extends StatelessWidget {
  const _Hidden({required this.pressed});

  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SparkBurst(),
                const SizedBox(width: 14),
                AnimatedScale(
                  scale: pressed ? 0.92 : 1,
                  duration: const Duration(milliseconds: 120),
                  child: const _Lock(),
                ),
                const SizedBox(width: 14),
                const SparkBurst(mirrored: true),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'SECRET CARD',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Color(0x803A0F99),
                    offset: Offset(0, 3),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'PRESS & HOLD TO\nREVEAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD9C8FF),
                letterSpacing: 0.6,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chunky white-lavender padlock with a soft 3D edge.
class _Lock extends StatelessWidget {
  const _Lock();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, 5),
          child: const Icon(
            Icons.lock_rounded,
            size: 120,
            color: Color(0xFF9F86D9),
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE6DCFF)],
          ).createShader(bounds),
          child: const Icon(Icons.lock_rounded, size: 120, color: Colors.white),
        ),
      ],
    );
  }
}

class _Revealed extends StatelessWidget {
  const _Revealed({required this.assignment});
  final PlayerAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final imposter = assignment.isImposter;
    const shadow = [
      Shadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 2),
    ];
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                imposter ? '🕵️' : '🤫',
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 10),
              Text(
                imposter ? 'YOU ARE' : 'YOUR SECRET WORD',
                style: AppTextStyles.label(
                  Colors.white70,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                imposter ? 'THE IMPOSTER' : (assignment.word ?? ''),
                textAlign: TextAlign.center,
                style: AppTextStyles.secret(
                  Colors.white,
                ).copyWith(shadows: shadow),
              ),
              if (imposter && assignment.hint != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'HINT',
                        style: AppTextStyles.label(AppColors.warmYellow),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment.hint!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline(AppColors.warmYellow),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                imposter ? 'Act natural.' : 'Remember your word.',
                style: AppTextStyles.body(
                  Colors.white,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
