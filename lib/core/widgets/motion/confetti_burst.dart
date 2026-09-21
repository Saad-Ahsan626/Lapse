import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/lapse_theme.dart';

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    required this.play,
    this.pieces = 36,
    this.duration = const Duration(milliseconds: 1600),
    this.colors,
    this.random,
    this.height = 220,
    super.key,
  });

  final bool play;
  final int pieces;
  final Duration duration;
  final List<Color>? colors;
  final Random? random;
  final double height;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Random _random = widget.random ?? Random();
  List<_Piece> _pieces = const [];
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.play) _burst();
  }

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (!oldWidget.play && widget.play) _burst();
  }

  void _burst() {
    if (reduceMotion(context)) return;
    final c = context.lapse.colors;
    final palette = widget.colors ?? [c.savings, c.trial, c.warning, c.primary];
    if (palette.isEmpty || widget.pieces <= 0) return;
    _pieces = List.generate(
      widget.pieces,
      (i) => _Piece(
        color: palette[i % palette.length],
        dot: _random.nextDouble() < 0.35,
        startX: (_random.nextDouble() - 0.5) * 0.3,
        velocityX: (_random.nextDouble() - 0.5) * 1.9,
        velocityY: -(0.45 + _random.nextDouble() * 0.55),
        gravity: 1.9 + _random.nextDouble() * 0.6,
        rotation: _random.nextDouble() * pi * 2,
        spin: (_random.nextDouble() - 0.5) * pi * 8,
      ),
    );
    _controller.value = 0;
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return SizedBox(height: widget.height);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          height: widget.height,
          child: CustomPaint(
            painter: _ConfettiPainter(
              pieces: _pieces,
              progress: _controller,
            ),
          ),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.color,
    required this.dot,
    required this.startX,
    required this.velocityX,
    required this.velocityY,
    required this.gravity,
    required this.rotation,
    required this.spin,
  });

  final Color color;
  final bool dot;
  final double startX;
  final double velocityX;
  final double velocityY;
  final double gravity;
  final double rotation;
  final double spin;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces, required this.progress})
    : super(repaint: progress);

  final List<_Piece> pieces;
  final Animation<double> progress;

  static const _rect = Size(6, 10);
  static const _dotRadius = 3.0;
  static const _fadeStart = 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1 || pieces.isEmpty) return;
    final opacity = t < _fadeStart ? 1.0 : (1 - t) / (1 - _fadeStart);
    final originX = size.width / 2;
    final originY = size.height * 0.12;
    final paint = Paint();
    for (final p in pieces) {
      final x = originX + (p.startX + p.velocityX * t) * size.width;
      final y =
          originY + (p.velocityY * t + 0.5 * p.gravity * t * t) * size.height;
      paint.color = p.color.withValues(alpha: p.color.a * opacity);
      if (p.dot) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
        continue;
      }
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.rotation + p.spin * t)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: _rect.width,
              height: _rect.height,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces || oldDelegate.progress != progress;
}
