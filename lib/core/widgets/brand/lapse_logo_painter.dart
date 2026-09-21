import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:lapse/core/widgets/rings/ring_geometry.dart';

class LapseLogoPainter extends CustomPainter {
  LapseLogoPainter({
    required this.color,
    this.arcFraction = 1 - RingGeometry.logoGapFraction,
    this.checkProgress = 1,
    this.rotation = 0,
  });

  final Color color;
  final double arcFraction;
  final double checkProgress;
  final double rotation;

  static const _unit = 48.0;
  static const _radius = 19.0;
  static const _stroke = 5.0;
  static const _check = [Offset(16, 24.6), Offset(21.6, 30.2), Offset(32, 19)];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / _unit;
    final paint = RingGeometry.stroke(color, _stroke * s)
      ..strokeJoin = StrokeJoin.round;

    if (arcFraction > 0) {
      final rect = Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: _radius * s,
      );
      canvas.drawArc(
        rect,
        RingGeometry.startAngle(RingGeometry.logoGapFraction) + rotation,
        2 * math.pi * arcFraction.clamp(0, 1),
        false,
        paint,
      );
    }

    if (checkProgress > 0) {
      final path = Path()
        ..moveTo(_check[0].dx * s, _check[0].dy * s)
        ..lineTo(_check[1].dx * s, _check[1].dy * s)
        ..lineTo(_check[2].dx * s, _check[2].dy * s);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * checkProgress.clamp(0, 1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(LapseLogoPainter old) =>
      old.color != color ||
      old.arcFraction != arcFraction ||
      old.checkProgress != checkProgress ||
      old.rotation != rotation;
}
