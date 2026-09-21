import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';

class TrialBadge extends StatelessWidget {
  const TrialBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Semantics(
      label: 'Free trial',
      excludeSemantics: true,
      child: Container(
        height: Sizes.badge,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: lapse.colors.trialStrong,
          borderRadius: BorderRadius.circular(Radii.badge),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            'TRIAL',
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.5),
            style: lapse.text.badge.copyWith(color: lapse.colors.onTrial),
          ),
        ),
      ),
    );
  }
}
