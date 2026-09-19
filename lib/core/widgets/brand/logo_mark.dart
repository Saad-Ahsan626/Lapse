import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/widgets/brand/lapse_logo_painter.dart';

class LogoMark extends StatelessWidget {
  const LogoMark({this.size = 48, this.color, super.key});

  final double size;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Lapse logo',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: LapseLogoPainter(
            color: color ?? context.lapse.colors.primary,
          ),
        ),
      ),
    );
  }
}
