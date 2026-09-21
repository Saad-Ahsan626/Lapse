import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class CancelIllustration extends StatelessWidget {
  const CancelIllustration({super.key});

  static const double _circle = 168;
  static const double _mark = 128;
  static const double _dot = 50;
  static const double _dotInner = 22;
  static const double _width = 208;
  static const double _height = 190;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    const cx = _width / 2;
    const cy = 6 + _circle / 2;
    const dotX = cx + 79;
    const dotY = cy + 66;

    return ExcludeSemantics(
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          children: [
            Positioned(
              left: cx - _circle / 2,
              top: cy - _circle / 2,
              child: Container(
                width: _circle,
                height: _circle,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.savingsTint,
                  shape: BoxShape.circle,
                ),
                child: LogoMark(size: _mark, color: c.savings),
              ),
            ),
            Positioned(
              left: dotX - _dot / 2,
              top: dotY - _dot / 2,
              child: Container(
                width: _dot,
                height: _dot,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: _dotInner,
                  height: _dotInner,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
