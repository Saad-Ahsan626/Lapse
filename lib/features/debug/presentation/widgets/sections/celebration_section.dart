import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class CelebrationSection extends StatefulWidget {
  const CelebrationSection({super.key});

  @override
  State<CelebrationSection> createState() => _CelebrationSectionState();
}

class _CelebrationSectionState extends State<CelebrationSection> {
  int _burst = 0;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Celebration',
      note: 'Mint badge and a 1.6s confetti burst. None under reduce motion.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SavingsBadge(),
                Positioned.fill(
                  child: ConfettiBurst(
                    key: ValueKey(_burst),
                    play: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          LapseButton(
            label: 'Replay confetti',
            variant: LapseButtonVariant.secondary,
            icon: Icons.celebration_rounded,
            onPressed: () => setState(() => _burst++),
          ),
        ],
      ),
    );
  }
}
