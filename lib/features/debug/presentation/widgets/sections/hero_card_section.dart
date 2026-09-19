import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class HeroCardSection extends StatelessWidget {
  const HeroCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final t = lapse.text;
    return GallerySection(
      title: 'Hero card',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.screen),
        decoration: BoxDecoration(
          gradient: lapse.colors.heroGradient,
          borderRadius: BorderRadius.circular(Radii.hero),
          boxShadow: lapse.colors.heroShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This month',
              style: t.meta.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text('Rs 4,320', style: t.moneyHero.copyWith(color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              'Rs 51,840 / year',
              style: t.meta.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
