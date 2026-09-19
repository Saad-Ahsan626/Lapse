import 'dart:math' as math;

import 'package:flutter/painting.dart';

abstract final class RingGeometry {
  static const double logoGapFraction = 14 / 119.4;

  static const double countdownGapFraction = 24 / 201;

  static double startAngle(double gapFraction) =>
      -math.pi / 2 + math.pi * gapFraction;

  static double fullSweep(double gapFraction) =>
      2 * math.pi * (1 - gapFraction);

  static Paint stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;
}
