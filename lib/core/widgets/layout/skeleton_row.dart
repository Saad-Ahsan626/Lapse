import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';

class SkeletonRow extends StatefulWidget {
  const SkeletonRow({this.height = 71, super.key});

  final double height;

  static const Duration shimmer = Motion.shimmer;

  @override
  State<SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<SkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SkeletonRow.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final isStatic = reduceMotion(context);
    final highlight = c.brightness == Brightness.dark
        ? c.ink.withValues(alpha: 0.08)
        : c.surface.withValues(alpha: 0.55);

    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(minHeight: widget.height),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: c.border),
            boxShadow: c.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: Sizes.serviceTile,
                height: Sizes.serviceTile,
                decoration: BoxDecoration(
                  color: c.tile,
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => isStatic
                        ? child!
                        : ShaderMask(
                            blendMode: BlendMode.srcATop,
                            shaderCallback: (bounds) => _sweep(
                              highlight,
                              _controller.value,
                            ).createShader(bounds),
                            child: child,
                          ),
                    child: _Bars(color: c.surfaceMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _sweep(Color highlight, double t) {
    final center = -0.5 + 2 * t;
    return LinearGradient(
      colors: [highlight.withAlpha(0), highlight, highlight.withAlpha(0)],
      stops: [
        (center - 0.3).clamp(0.0, 1.0),
        center.clamp(0.0, 1.0),
        (center + 0.3).clamp(0.0, 1.0),
      ],
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Bar(color: color, height: 12, widthFactor: 0.55),
        const SizedBox(height: Space.sm),
        _Bar(color: color, height: 10, widthFactor: 0.35),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.color,
    required this.height,
    required this.widthFactor,
  });

  final Color color;
  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
