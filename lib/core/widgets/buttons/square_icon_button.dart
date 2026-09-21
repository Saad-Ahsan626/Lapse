import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/buttons/press_scale.dart';

class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final borderRadius = BorderRadius.circular(Radii.control);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        excludeFromSemantics: true,
        child: PressScale(
          enabled: onPressed != null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: c.cardShadow,
            ),
            child: Material(
              color: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: borderRadius,
                side: BorderSide(color: c.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: SizedBox.square(
                  dimension: Sizes.minTap,
                  child: Center(child: Icon(icon, size: 22, color: c.ink)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
