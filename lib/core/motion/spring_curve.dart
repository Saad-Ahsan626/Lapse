import 'dart:math' as math;

import 'package:flutter/animation.dart';

class SpringCurve extends Curve {
  const SpringCurve({this.dampingRatio = 0.72})
    : assert(
        dampingRatio > 0 && dampingRatio < 1,
        'dampingRatio must be between 0 and 1',
      );

  final double dampingRatio;

  static const double _naturalFrequency = 10;

  double _raw(double t) {
    const omega = _naturalFrequency;
    final damped = omega * math.sqrt(1 - dampingRatio * dampingRatio);
    final decay = math.exp(-dampingRatio * omega * t);
    return 1 -
        decay *
            (math.cos(damped * t) +
                (dampingRatio * omega / damped) * math.sin(damped * t));
  }

  @override
  double transformInternal(double t) => _raw(t) + (1 - _raw(1)) * t;
}
