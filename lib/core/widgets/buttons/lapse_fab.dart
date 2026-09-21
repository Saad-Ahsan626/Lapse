import 'package:flutter/material.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/buttons/press_scale.dart';

class LapseFab extends StatelessWidget {
  const LapseFab({
    required this.onPressed,
    this.open = false,
    this.tooltip = 'Add subscription',
    super.key,
  });

  final VoidCallback? onPressed;
  final bool open;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    const shape = CircleBorder();

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: PressScale(
          enabled: onPressed != null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: c.heroShadow,
            ),
            child: Material(
              color: c.primary,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: shape,
                onTap: onPressed,
                child: SizedBox.square(
                  dimension: Sizes.fab,
                  child: Center(
                    child: AnimatedRotation(
                      turns: open ? 0.125 : 0,
                      duration: reduceMotion(context)
                          ? Duration.zero
                          : open
                          ? Motion.spring
                          : Motion.fade,
                      curve: open ? Motion.springCurve : Curves.easeInCubic,
                      child: Icon(
                        Icons.add_rounded,
                        size: 28,
                        color: c.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
