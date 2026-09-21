import 'package:flutter/material.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/widgets/rings/ring_geometry.dart';

class CountdownRing extends StatelessWidget {
  const CountdownRing({
    required this.progress,
    required this.color,
    this.size = 62,
    this.strokeRatio = 0.1,
    this.animate = true,
    this.child,
    this.semanticLabel,
    super.key,
  });

  final double progress;
  final Color color;
  final double size;

  final double strokeRatio;

  final bool animate;
  final Widget? child;
  final String? semanticLabel;

  static double clampProgress(double value) =>
      value.isNaN ? 0.03 : value.clamp(0.03, 1.0);

  @override
  Widget build(BuildContext context) {
    final track = context.lapse.colors.ringTrack;
    final target = clampProgress(progress);
    final duration = animate && !reduceMotion(context)
        ? Motion.ring
        : Duration.zero;

    final ring = RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: target),
          duration: duration,
          curve: Motion.emphasized,
          builder: (context, value, child) => CustomPaint(
            painter: _CountdownRingPainter(
              progress: value,
              color: color,
              track: track,
              strokeRatio: strokeRatio,
            ),
            child: child,
          ),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return ring;
    return Semantics(label: label, excludeSemantics: true, child: ring);
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.strokeRatio,
  });

  final double progress;
  final Color color;
  final Color track;
  final double strokeRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * strokeRatio;
    final radius = size.shortestSide / 2 - stroke;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    const gap = RingGeometry.countdownGapFraction;
    final start = RingGeometry.startAngle(gap);
    final sweep = RingGeometry.fullSweep(gap);

    canvas
      ..drawArc(rect, start, sweep, false, RingGeometry.stroke(track, stroke))
      ..drawArc(
        rect,
        start,
        sweep * progress,
        false,
        RingGeometry.stroke(color, stroke),
      );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.strokeRatio != strokeRatio;
}
