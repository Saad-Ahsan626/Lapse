import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/buttons/press_scale.dart';

class LapseCard extends StatelessWidget {
  const LapseCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    this.radius = Radii.card,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final borderRadius = BorderRadius.circular(radius);

    Widget card = DecoratedBox(
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
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap != null) card = PressScale(child: card);
    return card;
  }
}
