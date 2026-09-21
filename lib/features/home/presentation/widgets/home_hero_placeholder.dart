import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';

class HomeHeroPlaceholder extends StatelessWidget {
  const HomeHeroPlaceholder({super.key});

  static const double height = 168;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading totals',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.lapse.colors.surfaceMuted,
          borderRadius: BorderRadius.circular(Radii.hero),
        ),
      ),
    );
  }
}
