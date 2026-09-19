import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_typography.dart';
import 'package:lapse/core/widgets/brand/logo_mark.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({this.height = 48, this.color, this.textColor, super.key});

  final double height;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Semantics(
      label: 'Lapse',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoMark(size: height, color: color),
          SizedBox(width: height * 14 / 48),
          Text(
            'Lapse',
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: LapseTypography.fontFamily,
              fontSize: height * 40 / 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -height * 1.4 / 48,
              height: 1,
              color: textColor ?? lapse.colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
