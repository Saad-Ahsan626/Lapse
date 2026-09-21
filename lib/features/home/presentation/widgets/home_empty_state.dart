import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = context.lapse.text;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.screen,
        vertical: Space.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RingIllustration(onAdd: onAdd),
          const SizedBox(height: Space.xxxl + Space.sm),
          Text(
            'Nothing charging yet',
            textAlign: TextAlign.center,
            style: text.title.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: Space.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Add the first one and Lapse will start counting down to it.',
              textAlign: TextAlign.center,
              style: text.bodyMuted.copyWith(fontSize: 15),
            ),
          ),
          const SizedBox(height: Space.xxl),
          LapseButton(label: 'Add your first subscription', onPressed: onAdd),
        ],
      ),
    );
  }
}

class _RingIllustration extends StatelessWidget {
  const _RingIllustration({required this.onAdd});

  final VoidCallback onAdd;

  static const double size = 160;
  static const double tileSize = 64;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final radius = BorderRadius.circular(Radii.card);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _RingDotsPainter(
                  fill: c.surfaceMuted,
                  dot: c.borderStrong,
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Add subscription',
            excludeSemantics: true,
            onTap: onAdd,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: c.raisedShadow,
              ),
              child: Material(
                color: c.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                  side: BorderSide(color: c.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onAdd,
                  child: SizedBox.square(
                    dimension: tileSize,
                    child: Icon(Icons.add_rounded, size: 30, color: c.primary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingDotsPainter extends CustomPainter {
  const _RingDotsPainter({required this.fill, required this.dot});

  final Color fill;
  final Color dot;

  static const int count = 14;
  static const double dotLength = 16;
  static const double dotThickness = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    canvas.drawCircle(center, outer, Paint()..color = fill);
    final ring = outer * 0.8;
    final paint = Paint()..color = dot;
    for (var i = 0; i < count; i++) {
      final angle = 2 * math.pi * i / count - math.pi / 2;
      canvas
        ..save()
        ..translate(
          center.dx + ring * math.cos(angle),
          center.dy + ring * math.sin(angle),
        )
        ..rotate(angle + math.pi / 2)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: dotLength,
              height: dotThickness,
            ),
            const Radius.circular(dotThickness / 2),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_RingDotsPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.dot != dot;
}
