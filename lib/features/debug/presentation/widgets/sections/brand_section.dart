import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class BrandSection extends StatelessWidget {
  const BrandSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Brand',
      child: Wrap(
        spacing: Space.md,
        runSpacing: Space.md,
        children: [
          _BrandBox(
            background: LapseColors.light.background,
            child: LogoMark(color: LapseColors.light.primary),
          ),
          _BrandBox(
            background: LapseColors.dark.background,
            child: LogoMark(color: LapseColors.dark.primary),
          ),
          _BrandBox(
            background: LapseColors.light.primary,
            child: const LogoMark(color: Colors.white),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Space.md),
            child: Wordmark(height: 40),
          ),
        ],
      ),
    );
  }
}

class _BrandBox extends StatelessWidget {
  const _BrandBox({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: context.lapse.colors.border),
      ),
      child: child,
    );
  }
}
