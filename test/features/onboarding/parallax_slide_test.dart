import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/onboarding/presentation/widgets/parallax_slide.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/rebuild_counter.dart';

void main() {
  const illustrationKey = ValueKey('ill');
  const textKey = ValueKey('txt');

  Future<PageController> pumpSlide(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = PageController();
    addTearDown(controller.dispose);
    await tester.pumpLapse(
      Column(
        children: [
          SizedBox(
            height: 1,
            child: PageView(
              controller: controller,
              children: const [SizedBox(), SizedBox(), SizedBox()],
            ),
          ),
          Expanded(
            child: ParallaxSlide(
              controller: controller,
              index: 1,
              illustration: const SizedBox(key: illustrationKey, width: 100),
              text: const SizedBox(key: textKey, width: 100, height: 40),
            ),
          ),
        ],
      ),
      reduceMotion: reduceMotion,
    );
    return controller;
  }

  Future<void> scrollTo(
    WidgetTester tester,
    PageController controller,
    double page,
  ) async {
    controller.jumpTo(page * 390);
    await tester.pump();
  }

  double xOf(WidgetTester tester, Key key) =>
      tester.getTopLeft(find.byKey(key)).dx;

  testWidgets('moves illustration 0.4x and text 0.7x of the delta', (
    tester,
  ) async {
    final controller = await pumpSlide(tester);
    await scrollTo(tester, controller, 1);
    final illustrationBase = xOf(tester, illustrationKey);
    final textBase = xOf(tester, textKey);

    await scrollTo(tester, controller, 0.5);
    expect(
      xOf(tester, illustrationKey) - illustrationBase,
      closeTo(0.5 * 390 * 0.4, 0.001),
    );
    expect(xOf(tester, textKey) - textBase, closeTo(0.5 * 390 * 0.7, 0.001));
  });

  testWidgets('offsets are zero under reduce motion', (tester) async {
    final controller = await pumpSlide(tester, reduceMotion: true);
    await scrollTo(tester, controller, 1);
    final illustrationBase = xOf(tester, illustrationKey);
    final textBase = xOf(tester, textKey);

    await scrollTo(tester, controller, 0.5);
    expect(xOf(tester, illustrationKey), illustrationBase);
    expect(xOf(tester, textKey), textBase);
  });

  testWidgets('scrolling repaints the shift without rebuilding the slide', (
    tester,
  ) async {
    final controller = await pumpSlide(tester);
    final counter = RebuildCounter()..start();
    for (var i = 1; i <= 10; i++) {
      await scrollTo(tester, controller, i / 20);
    }
    expect(counter.of(ParallaxSlide), 0);
    expect(
      find.ancestor(
        of: find.byKey(illustrationKey),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
  });

  test('offsetFor scales the delta by width and factor', () {
    expect(
      ParallaxSlide.offsetFor(delta: 1, width: 390, factor: 0.4, reduce: true),
      0,
    );
    expect(
      ParallaxSlide.offsetFor(
        delta: -1,
        width: 390,
        factor: 0.7,
        reduce: false,
      ),
      closeTo(-273, 0.001),
    );
  });
}
