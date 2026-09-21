import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';

class WormIndicator extends StatelessWidget {
  const WormIndicator({required this.page, required this.count, super.key});

  final double page;
  final int count;

  static const double dotSize = 7;
  static const double activeWidth = 24;
  static const double gap = 6;

  static double widthFor(int index, double page) {
    final distance = (page - index).abs();
    final t = (1 - distance).clamp(0.0, 1.0);
    return dotSize + (activeWidth - dotSize) * t;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final current = page.round().clamp(0, count - 1) + 1;
    return Semantics(
      label: 'Page $current of $count',
      excludeSemantics: true,
      child: SizedBox(
        height: dotSize,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Container(
                key: ValueKey('worm-dot-$i'),
                width: widthFor(i, page),
                height: dotSize,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    c.borderStrong,
                    c.primary,
                    (1 - (page - i).abs()).clamp(0.0, 1.0),
                  ),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
