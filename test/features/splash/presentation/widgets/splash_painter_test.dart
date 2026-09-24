import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/splash/presentation/splash_timeline.dart';
import 'package:lapse/features/splash/presentation/widgets/splash_painter.dart';
import 'package:lapse/features/splash/presentation/widgets/splash_palette.dart';

const _palette = SplashPalette(
  primary: Color(0xFF4F46E5),
  primaryTint: Color(0x1F4F46E5),
  track: Color(0xFFF1F1F6),
  ink: Color(0xFF12121A),
  inkMuted: Color(0xFF5A5A6E),
);

SplashPainter _painter(
  Animation<double> progress, {
  SplashTimeline timeline = const SplashTimeline.full(),
  SplashPalette palette = _palette,
}) => SplashPainter(
  progress: progress,
  timeline: timeline,
  palette: palette,
  wordmarkStyle: const TextStyle(fontWeight: FontWeight.w800),
  taglineStyle: const TextStyle(fontWeight: FontWeight.w600),
  devicePixelRatio: 2,
);

Future<List<int>> _render(SplashPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Size(200, 300));
  final image = recorder.endRecording().toImageSync(200, 300);
  final bytes = await image.toByteData();
  image.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paints every frame of every sequence without throwing', () async {
    for (final timeline in const [
      SplashTimeline.full(),
      SplashTimeline.short(),
      SplashTimeline.reduced(),
    ]) {
      final progress = AnimationController(
        vsync: const TestVSync(),
        duration: timeline.duration,
      );
      final painter = _painter(progress, timeline: timeline);
      for (var i = 0; i <= 42; i++) {
        progress.value = i / 42;
        await _render(painter);
      }
      painter.dispose();
      progress.dispose();
    }
  });

  test('warms up every path offscreen once, without notifying', () {
    for (final timeline in const [
      SplashTimeline.full(),
      SplashTimeline.short(),
      SplashTimeline.reduced(),
    ]) {
      const progress = AlwaysStoppedAnimation<double>(0);
      final painter = _painter(progress, timeline: timeline);
      var notified = 0;
      painter.addListener(() => notified++);
      expect(painter.isWarm, isFalse);

      painter
        ..warmUp()
        ..warmUp();

      expect(painter.isWarm, isTrue);
      expect(painter.elapsedMs, 0);
      expect(notified, 0);
      painter.dispose();
    }

    final disposed = _painter(const AlwaysStoppedAnimation(0))
      ..dispose()
      ..warmUp();
    expect(disposed.isWarm, isFalse);
  });

  test('repaints from the animation it listens to', () {
    final progress = AnimationController(
      vsync: const TestVSync(),
      duration: SplashTimeline.fullDuration,
    );
    final painter = _painter(progress);
    var notified = 0;
    painter.addListener(() => notified++);
    progress
      ..value = 0.5
      ..value = 0.6;
    expect(notified, 2);
    expect(painter.elapsedMs, closeTo(0.6 * 2100, 1e-9));
    painter.dispose();
    progress.dispose();
  });

  test('draws the logo and the wordmark where the timeline says', () async {
    const logoMs = 0.2;
    final early = _painter(const AlwaysStoppedAnimation(logoMs));
    final late = _painter(const AlwaysStoppedAnimation(1600 / 2100));
    final earlyPixels = await _render(early);
    final latePixels = await _render(late);

    int inkAlpha(List<int> pixels, double top, double bottom) {
      var total = 0;
      for (var y = top.toInt(); y < bottom.toInt(); y++) {
        for (var x = 0; x < 200; x++) {
          if (pixels[(y * 200 + x) * 4 + 3] > 128) total++;
        }
      }
      return total;
    }

    const wordTop = 150 + SplashPainter.defaultLogoSize / 2 + 16;
    const wordBottom = wordTop + 40;
    expect(inkAlpha(earlyPixels, wordTop, wordBottom), 0);
    expect(inkAlpha(latePixels, wordTop, wordBottom), greaterThan(0));
    expect(inkAlpha(latePixels, 110, 190), greaterThan(0));
    early.dispose();
    late.dispose();
  });

  test('paints nothing once fully faded or disposed', () async {
    final end = _painter(const AlwaysStoppedAnimation(1));
    expect((await _render(end)).every((byte) => byte == 0), isTrue);
    end.dispose();

    final disposed = _painter(const AlwaysStoppedAnimation(0.5))..dispose();
    expect(disposed.isDisposed, isTrue);
    expect((await _render(disposed)).every((byte) => byte == 0), isTrue);
  });

  test('only asks to repaint when its configuration changes', () {
    const progress = AlwaysStoppedAnimation(0.3);
    final a = _painter(progress);
    final b = _painter(progress);
    final dark = _painter(
      progress,
      palette: const SplashPalette(
        primary: Color(0xFF818CF8),
        primaryTint: Color(0x29818CF8),
        track: Color(0xFF22222E),
        ink: Color(0xFFF4F4F8),
        inkMuted: Color(0xFFA0A0B4),
      ),
    );
    expect(b.shouldRepaint(a), isFalse);
    expect(dark.shouldRepaint(a), isTrue);
    expect(a.hitTest(Offset.zero), isFalse);
    for (final painter in [a, b, dark]) {
      painter.dispose();
    }
  });
}
