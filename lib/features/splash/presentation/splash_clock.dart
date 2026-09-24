import 'dart:math' as math;

import 'package:lapse/features/splash/presentation/splash_timeline.dart';

class SplashClock {
  SplashClock({required this.duration, this.maxStep = defaultMaxStep});

  static const Duration defaultMaxStep = SplashTimeline.maxFrameStep;

  final Duration duration;
  final Duration maxStep;

  Duration? _lastTick;
  int _elapsedMicros = 0;

  Duration get elapsed => Duration(microseconds: _elapsedMicros);

  double get progress =>
      duration <= Duration.zero ? 1 : _elapsedMicros / duration.inMicroseconds;

  bool get isDone => progress >= 1;

  double tick(Duration tickerElapsed) {
    final last = _lastTick;
    _lastTick = tickerElapsed;
    if (last != null) {
      final delta = math.max(0, (tickerElapsed - last).inMicroseconds);
      final step = math.min(delta, maxStep.inMicroseconds);
      _elapsedMicros = math.min(
        duration.inMicroseconds,
        _elapsedMicros + step,
      );
    }
    return progress;
  }
}
