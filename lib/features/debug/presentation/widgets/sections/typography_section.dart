import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.lapse.text;
    return GallerySection(
      title: 'Type scale',
      note: 'Plus Jakarta Sans. Money and counts use tabular figures.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeRow('40 / 800', Text('Rs 4,320', style: t.moneyHero)),
          _TypeRow('25 / 700', Text('Screen title', style: t.title)),
          _TypeRow('16.5 / 700', Text('Section header', style: t.section)),
          _TypeRow('15 / 600', Text('List item title', style: t.itemTitle)),
          _TypeRow('14 / 400', Text('Body and helper text', style: t.body)),
          _TypeRow('12.5 / 500', Text('Rs 299 · Monthly', style: t.meta)),
          _TypeRow('11 / 700', Text('CAPTION', style: t.caption)),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow(this.spec, this.sample);

  final String spec;
  final Widget sample;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec, style: context.lapse.text.caption),
          const SizedBox(height: 2),
          sample,
        ],
      ),
    );
  }
}
