import 'package:flutter/material.dart';

import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class TilesSection extends StatelessWidget {
  const TilesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GallerySection(
          title: 'Service tiles',
          note: 'Bundled logo → initials on brand colour → placeholder.',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ServiceTile(
                name: 'Netflix',
                initials: 'NF',
                brandColor: Color(0xFFE50914),
              ),
              ServiceTile(
                name: 'Spotify',
                initials: 'SP',
                brandColor: Color(0xFF1DB954),
              ),
              ServiceTile(
                name: 'YouTube Premium',
                initials: 'YT',
                brandColor: Color(0xFFFF0000),
              ),
              ServiceTile(name: 'Gym membership'),
              ServiceTile(name: 'iCloud+', initials: 'IC', size: 56),
              ServiceTile(
                name: 'Canva',
                initials: 'CV',
                brandColor: Color(0xFF00C4CC),
                size: 72,
              ),
            ],
          ),
        ),
        GallerySection(
          title: 'List tiles',
          child: Column(
            children: [
              SubscriptionListTile(
                name: 'Spotify Premium',
                meta: 'Rs 299 · Monthly',
                dueLabel: 'Tomorrow',
                urgency: Urgency.urgent,
                initials: 'SP',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              SubscriptionListTile(
                name: 'Netflix',
                meta: 'Rs 649 after trial',
                dueLabel: 'In 3 days',
                urgency: Urgency.warning,
                isTrial: true,
                initials: 'NF',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              SubscriptionListTile(
                name: 'iCloud+ 200GB',
                meta: 'Rs 390 · Monthly',
                dueLabel: 'Oct 24',
                urgency: Urgency.normal,
                initials: 'IC',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
