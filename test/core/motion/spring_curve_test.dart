import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/motion/spring_curve.dart';

void main() {
  group('SpringCurve', () {
    const curve = SpringCurve();

    List<double> samples() => [
      for (var i = 0; i <= 1000; i++) curve.transform(i / 1000),
    ];

    test('uses a damping ratio of 0.72 by default', () {
      expect(curve.dampingRatio, 0.72);
      expect(Motion.springCurve.dampingRatio, 0.72);
    });

    test('starts at 0 and ends exactly at 1', () {
      expect(curve.transform(0), 0);
      expect(curve.transform(1), 1);
      expect(curve.transformInternal(1), closeTo(1, 1e-12));
      expect(curve.transformInternal(0), closeTo(0, 1e-12));
    });

    test('overshoots slightly and settles', () {
      final values = samples();
      final peak = values.reduce((a, b) => a > b ? a : b);
      expect(peak, greaterThan(1.02));
      expect(peak, lessThan(1.06));
      final peakAt = values.indexOf(peak) / 1000;
      expect(peakAt, inInclusiveRange(0.3, 0.6));
      expect(curve.transform(0.9), closeTo(1, 0.01));
    });

    test('rises monotonically until the overshoot', () {
      final values = samples();
      final peakIndex = values.indexOf(
        values.reduce((a, b) => a > b ? a : b),
      );
      for (var i = 1; i <= peakIndex; i++) {
        expect(values[i], greaterThanOrEqualTo(values[i - 1]));
      }
      expect(curve.transform(0.1), greaterThan(0.2));
    });

    test('less damping overshoots more', () {
      double peak(Curve c) => [
        for (var i = 0; i <= 200; i++) c.transform(i / 200),
      ].reduce((a, b) => a > b ? a : b);
      expect(
        peak(const SpringCurve(dampingRatio: 0.4)),
        greaterThan(peak(curve)),
      );
    });
  });
}
