import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/motion/spring_curve.dart';

void main() {
  group('Motion tokens match the spec', () {
    test('entrances', () {
      expect(Motion.countUp, const Duration(milliseconds: 600));
      expect(Motion.stagger, const Duration(milliseconds: 40));
      expect(Motion.listItem, const Duration(milliseconds: 450));
      expect(Motion.hero, const Duration(milliseconds: 320));
    });

    test('attention and state', () {
      expect(Motion.urgentPulse, const Duration(seconds: 3));
      expect(Motion.ring, const Duration(milliseconds: 800));
      expect(Motion.emphasized, const Cubic(0.22, 1, 0.36, 1));
      expect(Motion.expand, const Duration(milliseconds: 280));
      expect(Motion.fieldFade, const Duration(milliseconds: 120));
    });

    test('touch and exits', () {
      expect(Motion.press, const Duration(milliseconds: 120));
      expect(Motion.release, const Duration(milliseconds: 180));
      expect(Motion.pressScale, 0.97);
      expect(Motion.spring, const Duration(milliseconds: 360));
      expect(Motion.springCurve, isA<SpringCurve>());
      expect(Motion.collapse, const Duration(milliseconds: 260));
    });

    test('component timings', () {
      expect(Motion.pressOpacity, const Duration(milliseconds: 150));
      expect(Motion.chip, const Duration(milliseconds: 180));
      expect(Motion.snap, const Duration(milliseconds: 220));
      expect(Motion.shimmer, const Duration(milliseconds: 1400));
    });

    test('the reduce-motion fade is 200ms', () {
      expect(Motion.fade, const Duration(milliseconds: 200));
    });
  });
}
