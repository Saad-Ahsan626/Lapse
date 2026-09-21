import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/widgets/brand/lapse_logo_painter.dart';
import 'package:lapse/core/widgets/rings/ring_geometry.dart';

class _RecordingCanvas extends Fake implements Canvas {
  final arcs = <({double start, double sweep})>[];
  int paths = 0;

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {
    arcs.add((start: startAngle, sweep: sweepAngle));
  }

  @override
  void drawPath(Path path, Paint paint) {
    paths++;
  }
}

void main() {
  const color = Color(0xFF4F46E5);
  const size = Size.square(48);
  final gapStart = RingGeometry.startAngle(RingGeometry.logoGapFraction);

  test('draws the resting mark by default', () {
    final canvas = _RecordingCanvas();
    LapseLogoPainter(color: color).paint(canvas, size);

    expect(canvas.arcs, hasLength(1));
    expect(canvas.arcs.single.start, closeTo(gapStart, 1e-9));
    expect(
      canvas.arcs.single.sweep,
      closeTo(RingGeometry.fullSweep(RingGeometry.logoGapFraction), 1e-9),
    );
    expect(canvas.paths, 1);
  });

  test('rotation offsets the start angle', () {
    final canvas = _RecordingCanvas();
    LapseLogoPainter(
      color: color,
      arcFraction: 1,
      rotation: -math.pi * RingGeometry.logoGapFraction,
    ).paint(canvas, size);

    expect(canvas.arcs.single.start, closeTo(-math.pi / 2, 1e-9));
    expect(canvas.arcs.single.sweep, closeTo(2 * math.pi, 1e-9));
  });

  test('skips empty parts', () {
    final canvas = _RecordingCanvas();
    LapseLogoPainter(
      color: color,
      arcFraction: 0,
      checkProgress: 0,
    ).paint(canvas, size);

    expect(canvas.arcs, isEmpty);
    expect(canvas.paths, 0);
  });

  test('repaints when any value changes', () {
    final base = LapseLogoPainter(color: color);

    expect(base.shouldRepaint(LapseLogoPainter(color: color)), isFalse);
    expect(
      base.shouldRepaint(LapseLogoPainter(color: color, rotation: 0.1)),
      isTrue,
    );
    expect(
      base.shouldRepaint(LapseLogoPainter(color: color, arcFraction: 0.5)),
      isTrue,
    );
    expect(
      base.shouldRepaint(LapseLogoPainter(color: color, checkProgress: 0.5)),
      isTrue,
    );
    expect(
      base.shouldRepaint(LapseLogoPainter(color: const Color(0xFF818CF8))),
      isTrue,
    );
  });
}
