import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_colors.dart';

/// In-app splash: the game name, then the Lazy Bear Club byline.
class StudioSplashScreen extends StatelessWidget {
  const StudioSplashScreen({super.key});

  static const bearAsset = 'assets/branding/lazy_bear_club.png';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? AppColors.deepNavy : const Color(0xFF6EC6FF);
    final scaler = MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: 1, maxScaleFactor: 1.35);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.indigo,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: const Color(0xFFE8C48A),
            ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: Scaffold(
          backgroundColor: background,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? const [
                        AppColors.deepNavy,
                        Color(0xFF1A0F3A),
                        AppColors.indigo,
                      ]
                    : const [Color(0xFF6EC6FF), Color(0xFFE8C48A)],
              ),
            ),
            child: const Stack(
              fit: StackFit.expand,
              children: [
                _CornerMarks(),
                SafeArea(child: _SplashLayout()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerMarks extends StatelessWidget {
  const _CornerMarks();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.brightViolet.withValues(alpha: dark ? 0.34 : 0.22);

    Widget mark(double size) {
      return Text(
        '?',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1,
        ),
      );
    }

    return IgnorePointer(
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 8, left: 18, child: mark(46)),
            Positioned(top: 26, right: 22, child: mark(32)),
          ],
        ),
      ),
    );
  }
}

class _SplashLayout extends StatelessWidget {
  const _SplashLayout();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = dark ? AppColors.warmYellow : AppColors.deepPurple;
    final bylineColor = dark ? AppColors.offWhite : AppColors.deepPurple;
    final accent = dark ? AppColors.electricBlue : AppColors.warmYellow;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Short landscape phones lay out on a taller canvas and scale down,
        // so the byline stays on screen instead of overflowing.
        const minDesignHeight = 560.0;
        final width = constraints.maxWidth;
        final height = math.max(constraints.maxHeight, minDesignHeight);
        final shortest = math.min(width, height);
        final titleSize = (shortest * 0.12).clamp(36.0, 68.0);
        final iconSize = (shortest * 0.16).clamp(56.0, 88.0);
        final nameSize = (shortest * 0.048).clamp(17.0, 24.0);
        final bySize = (shortest * 0.036).clamp(14.0, 18.0);
        final contentWidth = width - 56;

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: width,
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
              child: Column(
                children: [
                  const Spacer(),
                  Semantics(
                    header: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Imposter Game',
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display(
                          titleColor,
                        ).copyWith(fontSize: titleSize),
                      ),
                    ),
                  ),
                  SizedBox(height: titleSize * 0.22),
                  Container(
                    width: math.min(titleSize * 1.35, contentWidth * 0.28),
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const Spacer(),
                  _Byline(
                    color: bylineColor,
                    iconSize: iconSize,
                    nameSize: nameSize,
                    bySize: bySize,
                    maxWidth: contentWidth,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Byline extends StatelessWidget {
  const _Byline({
    required this.color,
    required this.iconSize,
    required this.nameSize,
    required this.bySize,
    required this.maxWidth,
  });

  final Color color;
  final double iconSize;
  final double nameSize;
  final double bySize;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final nameStyle = AppTextStyles.title(
      color,
    ).copyWith(fontSize: nameSize, height: 1.15, fontWeight: FontWeight.w800);
    final byStyle = AppTextStyles.label(
      color,
    ).copyWith(fontSize: bySize, letterSpacing: 0.8, height: 1);
    final textWidth = math.max(0.0, maxWidth - iconSize - 14);

    return Semantics(
      container: true,
      label: 'by The Lazy Bear Club',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _BearMark(size: iconSize),
            const SizedBox(width: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: textWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('by', style: byStyle),
                  const SizedBox(height: 2),
                  Text(
                    'The Lazy Bear Club',
                    style: nameStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BearMark extends StatelessWidget {
  const _BearMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withValues(alpha: 0.22),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          StudioSplashScreen.bearAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
