import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/widgets/brand/logo_mark.dart';

class SavingsBadge extends StatelessWidget {
  const SavingsBadge({this.size = 92, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.lapse.colors;
    return Semantics(
      label: 'Cancelled',
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.savingsTint,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: LogoMark(color: colors.savings, size: size * 0.56),
      ),
    );
  }
}
