import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class SpacingSection extends StatelessWidget {
  const SpacingSection({super.key});

  static const List<double> _spaces = [
    Space.xs,
    Space.sm,
    Space.md,
    Space.lg,
    Space.xl,
    Space.xxl,
    Space.xxxl,
  ];

  static const List<(String, double)> _radii = [
    ('12', Radii.sm),
    ('14', Radii.control),
    ('18', Radii.card),
    ('22', Radii.hero),
    ('pill', Radii.pill),
  ];

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return GallerySection(
      title: 'Spacing & radius',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.md,
            runSpacing: Space.md,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              for (final s in _spaces)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: s, height: s, color: lapse.colors.primary),
                    const SizedBox(height: Space.xs),
                    Text(s.toInt().toString(), style: lapse.text.meta),
                  ],
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.md,
            runSpacing: Space.md,
            children: [
              for (final (label, radius) in _radii)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 40,
                      decoration: BoxDecoration(
                        color: lapse.colors.primaryTint,
                        border: Border.all(color: lapse.colors.primary),
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(label, style: lapse.text.meta),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
