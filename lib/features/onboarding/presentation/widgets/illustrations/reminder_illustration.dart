import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class ReminderIllustration extends StatelessWidget {
  const ReminderIllustration({super.key});

  static const double _width = 280;
  static const double _height = 200;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    return ExcludeSemantics(
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: SizedBox(
          width: _width,
          height: _height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BellPainter(
                    bell: c.primary,
                    arcs: c.primary.withValues(alpha: c.isDark ? 0.3 : 0.2),
                    glow: c.primary.withValues(alpha: c.isDark ? 0.2 : 0.35),
                  ),
                ),
              ),
              Positioned(
                left: _width / 2 - 20,
                top: 72,
                child: LogoMark(size: 40, color: c.onPrimary),
              ),
              Positioned(
                right: 0,
                top: 8,
                child: _Pill(label: '3 days left', color: c.warningText),
              ),
              Positioned(
                left: 12,
                top: 162,
                child: _Pill(label: 'Tomorrow', color: c.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Text(
        label,
        style: lapse.text.chipSmall.copyWith(color: color, fontSize: 11.5),
      ),
    );
  }
}

class _BellPainter extends CustomPainter {
  _BellPainter({required this.bell, required this.arcs, required this.glow});

  final Color bell;
  final Color arcs;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const domeTop = 44.0;
    const half = 55.0;
    const domeCenterY = domeTop + half;
    const rimTop = 134.0;
    const rimBottom = 142.0;
    const rimHalf = 64.0;
    const clapperHalf = 11.0;
    const clapperBottom = 160.0;

    final arcPaint = Paint()
      ..color = arcs
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const start = -math.pi * 0.83;
    const sweep = math.pi * 0.5;
    for (final radius in const [78.0, 94.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, 104), radius: radius),
        start,
        sweep,
        false,
        arcPaint,
      );
    }

    final dome = Path()
      ..moveTo(cx - half, rimTop + 1)
      ..lineTo(cx - half, domeCenterY)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, domeCenterY), radius: half),
        math.pi,
        math.pi,
        false,
      )
      ..lineTo(cx + half, rimTop + 1)
      ..close();
    final rim = Path()
      ..addRRect(
        RRect.fromLTRBR(
          cx - rimHalf,
          rimTop,
          cx + rimHalf,
          rimBottom,
          const Radius.circular(4),
        ),
      );
    final clapper = Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          cx - clapperHalf,
          rimBottom - 1,
          cx + clapperHalf,
          clapperBottom,
          bottomLeft: const Radius.circular(clapperHalf),
          bottomRight: const Radius.circular(clapperHalf),
        ),
      );
    final shape = Path()
      ..addPath(dome, Offset.zero)
      ..addPath(rim, Offset.zero)
      ..addPath(clapper, Offset.zero);

    canvas
      ..save()
      ..translate(0, 10)
      ..drawPath(
        shape,
        Paint()
          ..color = glow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      )
      ..restore()
      ..drawPath(shape, Paint()..color = bell);
  }

  @override
  bool shouldRepaint(_BellPainter old) =>
      old.bell != bell || old.arcs != arcs || old.glow != glow;
}
