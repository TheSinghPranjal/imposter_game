import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/party_widgets.dart';

/// Hanging wooden sign drawn in code, for titles that change at runtime
/// (like a player's name). Matches the signs baked into the scene artwork.
class WoodSign extends StatelessWidget {
  const WoodSign({
    super.key,
    required this.line1,
    required this.line2,
    this.line1Size = 36,
  });

  /// Small white top line, e.g. "Your turn,".
  final String line1;
  final double line1Size;

  /// Big yellow bottom line, e.g. the player's name. May contain line breaks.
  final String line2;

  static const _ropeHeight = 900.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SparkBurst(),
        const SizedBox(width: 6),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Ropes run up off the top of the screen.
              for (final x in const [0.16, 0.84])
                Positioned.fill(
                  top: -_ropeHeight,
                  bottom: null,
                  child: Align(
                    alignment: Alignment(x * 2 - 1, 0),
                    child: const CustomPaint(
                      size: Size(12, _ropeHeight + 24),
                      painter: _RopePainter(),
                    ),
                  ),
                ),
              Transform.rotate(
                angle: -0.02,
                child: SizedBox(
                  width: double.infinity,
                  child: _Plank(
                    line1: line1,
                    line2: line2,
                    line1Size: line1Size,
                  ),
                ),
              ),
              // Leaf clusters where the ropes meet the plank.
              for (final (x, flip) in const [(0.16, false), (0.84, true)])
                Positioned.fill(
                  top: -28,
                  bottom: null,
                  child: Align(
                    alignment: Alignment(x * 2 - 1, 0),
                    child: Transform.flip(
                      flipX: flip,
                      child: const CustomPaint(
                        size: Size(76, 48),
                        painter: _LeavesPainter(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const SparkBurst(mirrored: true),
      ],
    );
  }
}

class _Plank extends StatelessWidget {
  const _Plank({
    required this.line1,
    required this.line2,
    required this.line1Size,
  });

  final String line1;
  final String line2;
  final double line1Size;

  @override
  Widget build(BuildContext context) {
    return _WoodSurface(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _OutlinedText(
              line1,
              fontSize: line1Size,
              fill: const LinearGradient(
                colors: [Colors.white, Color(0xFFF3ECE4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _OutlinedText(
              line2,
              fontSize: 48,
              fill: const LinearGradient(
                colors: [Color(0xFFFFEE7A), Color(0xFFFFB300)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small wooden strip with one line of white text and leafy corners.
class WoodBanner extends StatelessWidget {
  const WoodBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _WoodSurface(
          radius: 10,
          depth: 4,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(color: _outline, offset: Offset(0, 2)),
                  Shadow(color: _outline, blurRadius: 3),
                ],
              ),
            ),
          ),
        ),
        for (final (align, flip) in const [
          (Alignment.bottomLeft, false),
          (Alignment.topRight, true),
        ])
          Positioned.fill(
            left: -14,
            right: -14,
            top: -14,
            bottom: -14,
            child: Align(
              alignment: align,
              child: Transform.flip(
                flipX: flip,
                flipY: !flip,
                child: const CustomPaint(
                  size: Size(44, 28),
                  painter: _LeavesPainter(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

const _outline = Color(0xFF5E3212);

/// Painted wood: outline, warm gradient, grain, chunky bottom edge.
class _WoodSurface extends StatelessWidget {
  const _WoodSurface({
    required this.child,
    required this.radius,
    required this.padding,
    this.depth = 6,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double depth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _outline, width: 3),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD08A48), Color(0xFFB86D30), Color(0xFF9A5623)],
        ),
        boxShadow: [
          BoxShadow(color: _outline, offset: Offset(0, depth)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: Offset(0, depth * 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 3),
        child: CustomPaint(
          painter: const _GrainPainter(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Chunky title lettering: dark brown outline, drop shadow, gradient fill.
class _OutlinedText extends StatelessWidget {
  const _OutlinedText(this.text, {required this.fontSize, required this.fill});

  final String text;
  final double fontSize;
  final Gradient fill;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Nunito',
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 1.05,
    );
    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.16
              ..strokeJoin = StrokeJoin.round
              ..color = _outline,
            shadows: const [
              Shadow(color: Color(0x805E3212), offset: Offset(0, 4)),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: fill.createShader,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: style.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Soft top highlight.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.18),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    // Wavy grain lines and a plank seam.
    final rows = [0.3, 0.52, 0.74, 0.9];
    for (var i = 0; i < rows.length; i++) {
      final y = size.height * rows[i];
      final path = Path()..moveTo(size.width * 0.04, y);
      for (var x = 0.04; x <= 0.96; x += 0.04) {
        path.lineTo(size.width * x, y + math.sin(x * 14 + i * 2) * 1.6);
      }
      canvas.drawPath(
        path,
        paint
          ..strokeWidth = i == 1 ? 2.2 : 1.2
          ..color = const Color(
            0xFF6B3A16,
          ).withValues(alpha: i == 1 ? 0.35 : 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}

class _RopePainter extends CustomPainter {
  const _RopePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width / 2)),
      Paint()..color = const Color(0xFFC89150),
    );
    // Twisted strands.
    final strand = Paint()
      ..color = const Color(0xFF8A5A26)
      ..strokeWidth = 2;
    for (var y = 0.0; y < size.height; y += 7) {
      canvas.drawLine(Offset(0, y + 5), Offset(size.width, y), strand);
    }
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RopePainter old) => false;
}

class _LeavesPainter extends CustomPainter {
  const _LeavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // (centre x, centre y, angle, length, colour)
    const leaves = [
      (0.18, 0.62, -2.5, 0.42, Color(0xFF3E9B2A)),
      (0.62, 0.55, -0.5, 0.46, Color(0xFF4DAE32)),
      (0.36, 0.40, -1.7, 0.44, Color(0xFF6CC644)),
      (0.80, 0.78, 0.3, 0.36, Color(0xFF3E9B2A)),
      (0.46, 0.72, -1.0, 0.34, Color(0xFF7FD452)),
    ];
    for (final (cx, cy, angle, len, color) in leaves) {
      canvas.save();
      canvas.translate(w * cx, h * cy);
      canvas.rotate(angle);
      final l = w * len;
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(l * 0.5, -l * 0.32, l, 0)
        ..quadraticBezierTo(l * 0.5, l * 0.32, 0, 0);
      canvas.drawPath(
        path.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x552A5E12),
      );
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawLine(
        Offset(l * 0.1, 0),
        Offset(l * 0.85, 0),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 1.4,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LeavesPainter old) => false;
}
