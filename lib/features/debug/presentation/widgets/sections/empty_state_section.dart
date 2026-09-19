import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class EmptyStateSection extends StatelessWidget {
  const EmptyStateSection({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = context.lapse.colors.primary;
    return GallerySection(
      title: 'Empty state',
      child: LapseCard(
        padding: const EdgeInsets.symmetric(vertical: Space.xxl),
        child: EmptyState(
          illustration: CountdownRing(
            progress: 1,
            color: primary,
            size: 96,
            child: Icon(Icons.add_rounded, color: primary, size: 36),
          ),
          title: 'Nothing charging yet',
          message:
              'Add the first one and Lapse will start counting down to it.',
          primaryLabel: 'Add your first subscription',
          onPrimary: () {},
          secondaryLabel: 'Import a backup',
          onSecondary: () {},
        ),
      ),
    );
  }
}
