import 'package:flutter/material.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/theme.dart';

class ParallaxSlide extends StatelessWidget {
  const ParallaxSlide({
    required this.delta,
    required this.illustration,
    required this.text,
    super.key,
  });

  final double delta;
  final Widget illustration;
  final Widget text;

  static const double illustrationFactor = 0.4;
  static const double textFactor = 0.7;
  static const double illustrationHeight = 220;

  static double offsetFor({
    required double delta,
    required double width,
    required double factor,
    required bool reduce,
  }) => reduce ? 0 : delta * width * factor;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotion(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double shift(double factor) => offsetFor(
          delta: delta,
          width: width,
          factor: factor,
          reduce: reduce,
        );
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.translate(
                    key: const ValueKey('parallax-illustration'),
                    offset: Offset(shift(illustrationFactor), 0),
                    child: SizedBox(
                      height: illustrationHeight,
                      child: Center(child: illustration),
                    ),
                  ),
                  const SizedBox(height: Space.xxxl),
                  Transform.translate(
                    key: const ValueKey('parallax-text'),
                    offset: Offset(shift(textFactor), 0),
                    child: text,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
