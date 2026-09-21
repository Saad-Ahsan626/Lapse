import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/widgets/rings/ring_geometry.dart';
import 'package:lapse/features/splash/presentation/splash_timeline.dart';

void main() {
  const full = SplashTimeline.full();
  const rest = 1 - RingGeometry.logoGapFraction;
  const open = -math.pi * RingGeometry.logoGapFraction;

  group('full sequence', () {
    test('starts empty and strokes the ring by 500 ms', () {
      expect(full.arcFraction(0), 0);
      expect(full.arcRotation(0), closeTo(open, 1e-9));
      expect(full.arcFraction(250), inExclusiveRange(0.5, 1));
      expect(full.arcFraction(500), 1);
      expect(full.arcRotation(500), closeTo(open, 1e-9));
      expect(full.checkProgress(0), 0);
      expect(full.logoScale(0), 1);
      expect(full.opacity(0), 1);
      expect(full.wordmarkOpacity(0), 0);
      expect(full.wordmarkOffset(0), 8);
      expect(full.glowOpacity(0), 0);
    });

    test('depletes to the 12 o clock gap by 900 ms', () {
      expect(full.arcFraction(700), inExclusiveRange(rest, 1));
      expect(full.arcRotation(700), inExclusiveRange(open, 0));
      expect(full.arcFraction(900), closeTo(rest, 1e-9));
      expect(full.arcRotation(900), 0);
      expect(full.arcFraction(2100), closeTo(rest, 1e-9));
    });

    test('bumps the scale between 900 and 1100 ms', () {
      expect(full.logoScale(700), 1);
      expect(full.logoScale(900), 1);
      expect(full.logoScale(1000), closeTo(1.08, 1e-9));
      expect(full.logoScale(1100), 1);
    });

    test('draws the check with a glow pulse from 1100 to 1400 ms', () {
      expect(full.checkProgress(1100), 0);
      expect(full.glowOpacity(1100), 0);
      expect(full.checkProgress(1250), closeTo(0.5, 1e-9));
      expect(full.glowOpacity(1250), closeTo(1, 1e-9));
      expect(full.checkProgress(1400), 1);
      expect(full.glowOpacity(1400), 0);
    });

    test('fades the wordmark in and up from 1300 to 1600 ms', () {
      expect(full.wordmarkOpacity(1250), 0);
      expect(full.wordmarkOpacity(1400), inExclusiveRange(0, 1));
      expect(full.wordmarkOffset(1400), inExclusiveRange(0, 8));
      expect(full.wordmarkOpacity(1600), 1);
      expect(full.wordmarkOffset(1600), 0);
    });

    test('scales to 0.88 and fades out by 2100 ms', () {
      expect(full.logoScale(1600), 1);
      expect(full.opacity(1600), 1);
      expect(full.logoScale(1850), inExclusiveRange(0.88, 1));
      expect(full.opacity(1850), inExclusiveRange(0, 1));
      expect(full.logoScale(2100), closeTo(0.88, 1e-9));
      expect(full.opacity(2100), 0);
      expect(full.checkProgress(2100), 1);
    });
  });

  group('short sequence', () {
    const short = SplashTimeline.short();

    test('shows the complete mark with the wordmark, then exits', () {
      expect(short.arcFraction(0), closeTo(rest, 1e-9));
      expect(short.arcRotation(0), 0);
      expect(short.checkProgress(0), 1);
      expect(short.glowOpacity(100), 0);
      expect(short.wordmarkOpacity(0), 0);
      expect(short.wordmarkOpacity(200), 1);
      expect(short.wordmarkOffset(200), 0);
      expect(short.logoScale(300), 1);
      expect(short.opacity(300), 1);
      expect(short.logoScale(500), closeTo(0.88, 1e-9));
      expect(short.opacity(500), 0);
    });
  });

  group('reduced sequence', () {
    const reduced = SplashTimeline.reduced();

    test('is a plain fade of the complete logo', () {
      for (final ms in [0.0, 100.0, 200.0]) {
        expect(reduced.arcFraction(ms), closeTo(rest, 1e-9));
        expect(reduced.checkProgress(ms), 1);
        expect(reduced.logoScale(ms), 1);
        expect(reduced.glowOpacity(ms), 0);
        expect(reduced.wordmarkOpacity(ms), 1);
        expect(reduced.wordmarkOffset(ms), 0);
      }
      expect(reduced.opacity(0), 1);
      expect(reduced.opacity(100), inExclusiveRange(0, 1));
      expect(reduced.opacity(200), 0);
    });
  });

  test('durations', () {
    expect(full.duration, const Duration(milliseconds: 2100));
    expect(
      const SplashTimeline.short().duration,
      const Duration(milliseconds: 500),
    );
    expect(
      const SplashTimeline.reduced().duration,
      const Duration(milliseconds: 200),
    );
    expect(full.durationMs, 2100);
  });

  test('forLaunch picks the sequence', () {
    expect(
      SplashTimeline.forLaunch(
        onboardingDone: false,
        reduceMotion: false,
      ).isFull,
      isTrue,
    );
    expect(
      SplashTimeline.forLaunch(
        onboardingDone: true,
        reduceMotion: false,
      ).isShort,
      isTrue,
    );
    expect(
      SplashTimeline.forLaunch(
        onboardingDone: false,
        reduceMotion: true,
      ).isReduced,
      isTrue,
    );
    expect(
      SplashTimeline.forLaunch(
        onboardingDone: true,
        reduceMotion: true,
      ).isReduced,
      isTrue,
    );
  });
}
