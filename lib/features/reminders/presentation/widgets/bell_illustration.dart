import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class BellIllustration extends StatelessWidget {
  const BellIllustration({this.size = 200, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BellPainter(
                  primary: c.primary,
                  tint: c.primaryTint,
                  ring: c.primary.withValues(alpha: 0.3),
                  shadow: c.primary.withValues(alpha: c.isDark ? 0.18 : 0.35),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.18),
              child: LogoMark(size: size * 0.24, color: c.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BellPainter extends CustomPainter {
  _BellPainter({
    required this.primary,
    required this.tint,
    required this.ring,
    required this.shadow,
  });

  final Color primary;
  final Color tint;
  final Color ring;
  final Color shadow;

  static const _dashes = 30;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);

    canvas.drawCircle(center, s * 0.44, Paint()..color = tint);

    final ringPaint = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.01
      ..strokeCap = StrokeCap.round;
    final ringRect = Rect.fromCircle(center: center, radius: s * 0.49);
    const step = 2 * math.pi / _dashes;
    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(ringRect, i * step, step * 0.45, false, ringPaint);
    }

    final bell = _bellPath(center, s);
    canvas
      ..save()
      ..translate(0, s * 0.04)
      ..drawPath(
        bell,
        Paint()
          ..color = shadow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06),
      )
      ..restore()
      ..drawPath(bell, Paint()..color = primary);
  }

  Path _bellPath(Offset center, double s) {
    final half = s * 0.26;
    final domeCenterY = center.dy - s * 0.05;
    final rimTop = center.dy + s * 0.10;
    final rimBottom = center.dy + s * 0.145;
    final rimHalf = s * 0.295;
    final clapperHalf = s * 0.0525;
    final clapperBottom = center.dy + s * 0.24;

    final dome = Path()
      ..moveTo(center.dx - half, rimTop + 1)
      ..lineTo(center.dx - half, domeCenterY)
      ..arcTo(
        Rect.fromCircle(
          center: Offset(center.dx, domeCenterY),
          radius: half,
        ),
        math.pi,
        math.pi,
        false,
      )
      ..lineTo(center.dx + half, rimTop + 1)
      ..close();

    final rim = Path()
      ..addRRect(
        RRect.fromLTRBR(
          center.dx - rimHalf,
          rimTop,
          center.dx + rimHalf,
          rimBottom,
          Radius.circular(s * 0.0225),
        ),
      );

    final clapper = Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          center.dx - clapperHalf,
          rimBottom - 1,
          center.dx + clapperHalf,
          clapperBottom,
          bottomLeft: Radius.circular(clapperHalf),
          bottomRight: Radius.circular(clapperHalf),
        ),
      );

    return Path()
      ..addPath(dome, Offset.zero)
      ..addPath(rim, Offset.zero)
      ..addPath(clapper, Offset.zero);
  }

  @override
  bool shouldRepaint(_BellPainter old) =>
      old.primary != primary ||
      old.tint != tint ||
      old.ring != ring ||
      old.shadow != shadow;
}
