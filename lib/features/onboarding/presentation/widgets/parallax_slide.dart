import 'package:flutter/material.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/theme.dart';

class ParallaxSlide extends StatelessWidget {
  const ParallaxSlide({
    required this.controller,
    required this.index,
    required this.illustration,
    required this.text,
    super.key,
  });

  final PageController controller;
  final int index;
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

  static double pageOf(PageController controller) {
    if (controller.hasClients && controller.position.haveDimensions) {
      return controller.page ?? 0;
    }
    return controller.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotion(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        Widget shifted(Key key, double factor, Widget child) {
          if (reduce) return child;
          return AnimatedBuilder(
            key: key,
            animation: controller,
            child: child,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                offsetFor(
                  delta: index - pageOf(controller),
                  width: width,
                  factor: factor,
                  reduce: reduce,
                ),
                0,
              ),
              child: child,
            ),
          );
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  shifted(
                    const ValueKey('parallax-illustration'),
                    illustrationFactor,
                    RepaintBoundary(
                      child: SizedBox(
                        height: illustrationHeight,
                        child: Center(child: illustration),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.xxxl),
                  shifted(
                    const ValueKey('parallax-text'),
                    textFactor,
                    text,
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
