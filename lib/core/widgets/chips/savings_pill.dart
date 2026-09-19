import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';

class SavingsPill extends StatelessWidget {
  const SavingsPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Container(
      height: Sizes.chipSmall,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: lapse.colors.savingsTint,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          style: lapse.text.chipSmall.copyWith(
            color: lapse.colors.savingsText,
          ),
        ),
      ),
    );
  }
}
