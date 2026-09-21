import 'dart:math' as math;

import 'package:flutter/animation.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/widgets/rings/ring_geometry.dart';

enum _Sequence { full, short, reduced }

class SplashTimeline {
  const SplashTimeline.full() : _sequence = _Sequence.full;

  const SplashTimeline.short() : _sequence = _Sequence.short;

  const SplashTimeline.reduced() : _sequence = _Sequence.reduced;

  factory SplashTimeline.forLaunch({
    required bool onboardingDone,
    required bool reduceMotion,
  }) {
    if (reduceMotion) return const SplashTimeline.reduced();
    if (onboardingDone) return const SplashTimeline.short();
    return const SplashTimeline.full();
  }

  static const fullDuration = Duration(milliseconds: 2100);
  static const shortDuration = Duration(milliseconds: 500);
  static const Duration reducedDuration = Motion.fade;

  static const double restArcFraction = 1 - RingGeometry.logoGapFraction;
  static const double bumpScale = 1.08;
  static const double exitScale = 0.88;
  static const double wordmarkRise = 8;

  static const double _openRotation = -math.pi * RingGeometry.logoGapFraction;

  final _Sequence _sequence;

  bool get isFull => _sequence == _Sequence.full;
  bool get isShort => _sequence == _Sequence.short;
  bool get isReduced => _sequence == _Sequence.reduced;

  Duration get duration => switch (_sequence) {
    _Sequence.full => fullDuration,
    _Sequence.short => shortDuration,
    _Sequence.reduced => reducedDuration,
  };

  double get durationMs => duration.inMilliseconds.toDouble();

  double arcFraction(double ms) {
    if (!isFull) return restArcFraction;
    if (ms <= 500) return Curves.easeOut.transform(_progress(ms, 0, 500));
    final t = Curves.easeInOut.transform(_progress(ms, 500, 900));
    return 1 - (1 - restArcFraction) * t;
  }

  double arcRotation(double ms) {
    if (!isFull) return 0;
    if (ms <= 500) return _openRotation;
    final t = Curves.easeInOut.transform(_progress(ms, 500, 900));
    return _openRotation * (1 - t);
  }

  double checkProgress(double ms) {
    if (!isFull) return 1;
    return Curves.easeInOut.transform(_progress(ms, 1100, 1400));
  }

  double glowOpacity(double ms) {
    if (!isFull || ms <= 1100 || ms >= 1400) return 0;
    return math.sin(math.pi * _progress(ms, 1100, 1400));
  }

  double logoScale(double ms) {
    switch (_sequence) {
      case _Sequence.reduced:
        return 1;
      case _Sequence.short:
        return _exitScale(ms, 300, 500);
      case _Sequence.full:
        if (ms > 900 && ms < 1100) {
          final bump = math.sin(math.pi * _progress(ms, 900, 1100));
          return 1 + (bumpScale - 1) * bump;
        }
        return _exitScale(ms, 1600, 2100);
    }
  }

  double wordmarkOpacity(double ms) => switch (_sequence) {
    _Sequence.reduced => 1,
    _Sequence.short => Curves.easeOut.transform(_progress(ms, 0, 200)),
    _Sequence.full => Curves.easeOut.transform(_progress(ms, 1300, 1600)),
  };

  double wordmarkOffset(double ms) =>
      isReduced ? 0 : wordmarkRise * (1 - wordmarkOpacity(ms));

  double opacity(double ms) {
    final t = switch (_sequence) {
      _Sequence.reduced => _progress(ms, 0, durationMs),
      _Sequence.short => _progress(ms, 300, 500),
      _Sequence.full => _progress(ms, 1600, 2100),
    };
    return 1 - Curves.easeIn.transform(t);
  }

  double _exitScale(double ms, double start, double end) {
    final t = Curves.easeIn.transform(_progress(ms, start, end));
    return 1 - (1 - exitScale) * t;
  }

  static double _progress(double ms, double start, double end) =>
      ((ms - start) / (end - start)).clamp(0.0, 1.0);
}
