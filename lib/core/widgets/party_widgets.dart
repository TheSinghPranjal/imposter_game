import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';

class PartyScaffold extends StatelessWidget {
  const PartyScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [
                    AppColors.deepNavy,
                    Color(0xFF1A0F3A),
                    AppColors.indigo,
                  ]
                : const [
                    Color(0xFFF3EEFF),
                    AppColors.offWhite,
                    Color(0xFFE8F6FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class GlowCard extends StatelessWidget {
  const GlowCard({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color ?? (dark ? AppColors.cardDark : AppColors.cardLight),
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.brightViolet.withValues(alpha: dark ? 0.25 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FloatingMarks extends StatelessWidget {
  const FloatingMarks({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 40,
            right: 24,
            child:
                Text(
                      '?',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brightViolet.withValues(alpha: 0.15),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: 10, duration: 2800.ms),
          ),
          Positioned(
            bottom: 120,
            left: 18,
            child:
                Icon(
                      Icons.visibility_off_rounded,
                      size: 42,
                      color: AppColors.coral.withValues(alpha: 0.18),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -8, duration: 3200.ms),
          ),
        ],
      ),
    );
  }
}

enum CandyButtonStyle { primary, secondary, cream }

/// Chunky, glossy pill button used on the home screen.
class CandyButton extends StatefulWidget {
  const CandyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.style = CandyButtonStyle.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Shown at the right end inside a darker circle, e.g. a forward arrow.
  final IconData? trailingIcon;
  final CandyButtonStyle style;

  @override
  State<CandyButton> createState() => _CandyButtonState();
}

class _CandyButtonState extends State<CandyButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.style == CandyButtonStyle.primary;
    final height = primary ? 68.0 : 58.0;
    final depth = primary ? 6.0 : 5.0;
    final radius = BorderRadius.circular(height / 2);

    final face = switch (widget.style) {
      CandyButtonStyle.primary => const [
        Color(0xFFA56BFF),
        Color(0xFF7B3CF0),
        Color(0xFF6A2BE0),
      ],
      CandyButtonStyle.secondary => const [
        Color(0xFFFFFFFF),
        Color(0xFFF7F3F8),
        Color(0xFFECE6EE),
      ],
      CandyButtonStyle.cream => const [
        Color(0xFFFFFBF0),
        Color(0xFFFFF3DC),
        Color(0xFFFCE9C6),
      ],
    };
    final base = switch (widget.style) {
      CandyButtonStyle.primary => const Color(0xFF4B1AA8),
      CandyButtonStyle.secondary => const Color(0xFFCFC6D6),
      CandyButtonStyle.cream => const Color(0xFFE2C48F),
    };
    final rim = primary ? const Color(0xFFD9C4FF) : const Color(0xFFFFFFFF);
    final fg = primary ? Colors.white : AppColors.deepPurple;
    final offset = _pressed ? depth - 2 : 0.0;
    final enabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: GestureDetector(
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: SizedBox(
            height: height + depth,
            child: Stack(
              children: [
                // 3D base / drop shadow.
                Positioned.fill(
                  top: depth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (primary ? AppColors.brightViolet : Colors.black)
                                  .withValues(alpha: primary ? 0.45 : 0.18),
                          blurRadius: primary ? 22 : 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
                // Face.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 80),
                  left: 0,
                  right: 0,
                  top: offset,
                  height: height,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: rim, width: primary ? 3 : 2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: face,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Glossy highlight.
                        Positioned(
                          top: 5,
                          left: height * 0.45,
                          right: height * 0.45,
                          height: height * 0.28,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: radius,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: primary ? 0.35 : 0.9,
                                  ),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Keep the label clear of the trailing circle, and
                        // pad both sides so it stays centred.
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.trailingIcon != null
                                ? height - 4
                                : 16,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    size: primary ? 34 : 26,
                                    color: fg,
                                  ),
                                  SizedBox(width: primary ? 18 : 14),
                                ],
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      widget.label,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: primary ? 24 : 19,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: fg,
                                        shadows: primary
                                            ? const [
                                                Shadow(
                                                  color: Color(0x664B1AA8),
                                                  offset: Offset(0, 2),
                                                  blurRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (widget.trailingIcon != null)
                          Positioned(
                            right: 8,
                            top: 8,
                            bottom: 8,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary
                                      ? const Color(0x33200060)
                                      : base.withValues(alpha: 0.35),
                                ),
                                child: Icon(
                                  widget.trailingIcon,
                                  color: fg,
                                  size: height * 0.45,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three little yellow "excitement" dashes, drawn beside titles.
class SparkBurst extends StatelessWidget {
  const SparkBurst({super.key, this.mirrored = false});

  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: mirrored,
      child: const CustomPaint(
        size: Size(26, 44),
        painter: _SparkBurstPainter(),
      ),
    );
  }
}

class _SparkBurstPainter extends CustomPainter {
  const _SparkBurstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.warmYellow
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;
    canvas.drawLine(
      Offset(w * 0.35, h * 0.12),
      Offset(w * 0.8, h * 0.3),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.15, h * 0.5),
      Offset(w * 0.75, h * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.35, h * 0.88),
      Offset(w * 0.8, h * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SparkBurstPainter old) => false;
}
