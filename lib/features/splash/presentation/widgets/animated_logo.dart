import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/splash/presentation/splash_timeline.dart';

class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    required this.timeline,
    required this.elapsedMs,
    this.size = defaultSize,
    super.key,
  });

  static const double defaultSize = 96;

  final SplashTimeline timeline;
  final double elapsedMs;
  final double size;

  double get _wordmarkHeight => size * 0.3;

  @override
  Widget build(BuildContext context) {
    final colors = context.lapse.colors;
    final ms = elapsedMs;
    final glow = timeline.glowOpacity(ms);
    final slot = Space.lg + _wordmarkHeight;
    return Opacity(
      opacity: timeline.opacity(ms),
      child: Transform.scale(
        scale: timeline.logoScale(ms),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: slot),
            SizedBox.square(
              dimension: size,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (glow > 0)
                    DecoratedBox(
                      key: const ValueKey('splash-glow'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(
                              alpha: 0.45 * glow,
                            ),
                            blurRadius: size * 0.35,
                            spreadRadius: size * 0.04,
                          ),
                        ],
                      ),
                      child: SizedBox.square(dimension: size * 0.42),
                    ),
                  CustomPaint(
                    size: Size.square(size),
                    painter: LapseLogoPainter(
                      color: colors.primary,
                      arcFraction: timeline.arcFraction(ms),
                      rotation: timeline.arcRotation(ms),
                      checkProgress: timeline.checkProgress(ms),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            SizedBox(
              height: _wordmarkHeight,
              child: Opacity(
                opacity: timeline.wordmarkOpacity(ms),
                child: Transform.translate(
                  offset: Offset(0, timeline.wordmarkOffset(ms)),
                  child: Text(
                    'Lapse',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontFamily: LapseTypography.fontFamily,
                      fontSize: _wordmarkHeight,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -_wordmarkHeight * 1.4 / 40,
                      height: 1,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
