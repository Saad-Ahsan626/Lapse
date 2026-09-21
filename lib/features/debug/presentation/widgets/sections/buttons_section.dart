import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class ButtonsSection extends StatelessWidget {
  const ButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Buttons',
      note: '48px height, 0.97 scale on press.',
      child: Wrap(
        spacing: Space.md,
        runSpacing: Space.md,
        children: [
          LapseButton(label: 'Save subscription', onPressed: () {}),
          LapseButton(
            label: 'Mark as cancelled',
            variant: LapseButtonVariant.secondary,
            onPressed: () {},
          ),
          LapseButton(
            label: 'Maybe later',
            variant: LapseButtonVariant.text,
            onPressed: () {},
          ),
          LapseButton(
            label: 'Delete',
            variant: LapseButtonVariant.danger,
            onPressed: () {},
          ),
          LapseButton(
            label: 'Done',
            variant: LapseButtonVariant.inverse,
            onPressed: () {},
          ),
          const LapseButton(label: 'Disabled', onPressed: null),
          LapseButton(
            label: 'Cancel now',
            trailingIcon: Icons.north_east_rounded,
            expand: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
