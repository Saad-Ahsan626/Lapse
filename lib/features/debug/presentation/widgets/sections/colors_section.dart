import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class ColorsSection extends StatelessWidget {
  const ColorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final swatches = [
      ('Primary', c.primary),
      ('Savings', c.savings),
      ('Trial', c.trial),
      ('Urgent ≤1d', c.urgent),
      ('Warning ≤3d', c.warning),
      ('Background', c.background),
      ('Surface', c.surface),
      ('Surface muted', c.surfaceMuted),
      ('Tile', c.tile),
      ('Input fill', c.inputFill),
      ('Ink', c.ink),
      ('Ink muted', c.inkMuted),
      ('Ink subtle', c.inkSubtle),
    ];

    return GallerySection(
      title: 'Color',
      note: 'Semantic roles. Urgency is never carried by colour alone.',
      child: Wrap(
        spacing: Space.md,
        runSpacing: Space.lg,
        children: [
          for (final (name, color) in swatches)
            _Swatch(name: name, color: color),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final hex = color
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: lapse.colors.border),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: lapse.text.meta.copyWith(color: lapse.colors.ink)),
          Text('#$hex', style: lapse.text.meta),
        ],
      ),
    );
  }
}
