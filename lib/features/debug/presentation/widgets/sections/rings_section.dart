import 'package:flutter/material.dart';

import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class RingsSection extends StatelessWidget {
  const RingsSection({super.key});

  static const List<(int, double, Urgency)> _samples = [
    (1, 26 / 177, Urgency.urgent),
    (3, 60 / 177, Urgency.warning),
    (18, 140 / 177, Urgency.normal),
  ];

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final t = lapse.text;
    return GallerySection(
      title: 'Countdown ring',
      note: "Gap at 12 o'clock. Colour by urgency, always with text.",
      child: Wrap(
        spacing: Space.xl,
        runSpacing: Space.lg,
        children: [
          for (final (days, progress, urgency) in _samples)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountdownRing(
                  progress: progress,
                  color: lapse.colors.urgencyAccent(urgency),
                  child: Text(
                    '$days',
                    style: LapseTypography.money(t.itemTitle),
                  ),
                ),
                const SizedBox(height: Space.sm),
                Text(days == 1 ? '1 day' : '$days days', style: t.meta),
              ],
            ),
          CountdownRing(
            progress: 60 / 177,
            color: lapse.colors.warning,
            size: 150,
            strokeRatio: 0.07,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('3', style: t.moneyHero, textScaler: TextScaler.noScaling),
                Text(
                  'days left',
                  style: t.meta,
                  textScaler: TextScaler.noScaling,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
