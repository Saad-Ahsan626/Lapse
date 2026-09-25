import 'dart:math' as math;

import 'package:flutter/animation.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/widgets/rings/ring_geometry.dart';

class SplashTimeline {
  const SplashTimeline.full() : isReduced = false;

  const SplashTimeline.reduced() : isReduced = true;

  factory SplashTimeline.forLaunch({required bool reduceMotion}) => reduceMotion
      ? const SplashTimeline.reduced()
      : const SplashTimeline.full();

  static const fullDuration = Duration(milliseconds: 2100);
  static const Duration reducedDuration = Motion.fade;
  static const maxFrameStep = Duration(milliseconds: 32);

  static const double restArcFraction = 1 - RingGeometry.logoGapFraction;
  static const double bumpScale = 1.08;
  static const double exitScale = 0.88;
  static const double wordmarkRise = 8;
  static const String wordmark = 'Lapse';
  static const String tagline = 'Cancel before it charges';

  static const double _openRotation = -math.pi * RingGeometry.logoGapFraction;
  static const double _bumpAmplitude = 0.168;
  static const double _letterStart = 1250;
  static const double _letterGap = 35;
  static const double _letterLength = 200;
  static const int _warmUpSteps = 8;

  final bool isReduced;

  bool get isFull => !isReduced;

  Duration get duration => isReduced ? reducedDuration : fullDuration;

  double get durationMs => duration.inMilliseconds.toDouble();

  double arcFraction(double ms) {
    if (isReduced) return restArcFraction;
    if (ms <= 500) return Curves.easeOut.transform(_progress(ms, 0, 500));
    final t = Curves.easeInOut.transform(_progress(ms, 500, 900));
    return 1 - (1 - restArcFraction) * t;
  }

  double arcRotation(double ms) {
    if (isReduced) return 0;
    if (ms <= 500) return _openRotation;
    final t = Curves.easeInOut.transform(_progress(ms, 500, 900));
    return _openRotation * (1 - t);
  }

  double trackOpacity(double ms) {
    if (isReduced) return 0;
    if (ms <= 150) return Curves.easeOut.transform(_progress(ms, 0, 150));
    return 1 - Curves.easeIn.transform(_progress(ms, 900, 1100));
  }

  double headGlow(double ms) {
    if (isReduced || ms >= 700) return 0;
    if (ms <= 100) return _progress(ms, 0, 100);
    if (ms <= 500) return 1;
    return 1 - _progress(ms, 500, 700);
  }

  double checkProgress(double ms) {
    if (isReduced) return 1;
    return Curves.easeInOut.transform(_progress(ms, 1100, 1400));
  }

  double glowOpacity(double ms) {
    if (isReduced || ms <= 1100 || ms >= 1400) return 0;
    return math.sin(math.pi * _progress(ms, 1100, 1400));
  }

  double? rippleProgress(double ms) {
    if (isReduced || ms < 900 || ms >= 1500) return null;
    return Curves.easeOut.transform(_progress(ms, 900, 1500));
  }

  double backgroundGlow(double ms) =>
      isReduced ? 0 : Curves.easeOut.transform(_progress(ms, 0, 600));

  double logoScale(double ms) {
    if (isReduced) return 1;
    if (ms > 900 && ms < 1100) {
      final t = _progress(ms, 900, 1100);
      return 1 +
          _bumpAmplitude * math.exp(-3.5 * t) * math.sin(2 * math.pi * t);
    }
    final t = Curves.easeIn.transform(_progress(ms, 1600, 2100));
    return 1 - (1 - exitScale) * t;
  }

  double letterProgress(int index, double ms) {
    if (isReduced) return 1;
    final start = _letterStart + index * _letterGap;
    return Curves.easeOut.transform(
      _progress(ms, start, start + _letterLength),
    );
  }

  double letterOffset(int index, double ms) =>
      wordmarkRise * (1 - letterProgress(index, ms));

  double wordmarkOpacity(double ms) => letterProgress(wordmark.length - 1, ms);

  double wordmarkOffset(double ms) =>
      isReduced ? 0 : wordmarkRise * (1 - wordmarkOpacity(ms));

  double taglineOpacity(double ms) =>
      isReduced ? 1 : Curves.easeOut.transform(_progress(ms, 1450, 1650));

  double opacity(double ms) {
    final t = isReduced
        ? _progress(ms, 0, durationMs)
        : _progress(ms, 1600, 2100);
    return 1 - Curves.easeIn.transform(t);
  }

  List<double> get warmUpMoments => [
    for (var step = 1; step < _warmUpSteps; step++)
      durationMs * step / _warmUpSteps,
  ];

  static double _progress(double ms, double start, double end) =>
      ((ms - start) / (end - start)).clamp(0.0, 1.0);
}
