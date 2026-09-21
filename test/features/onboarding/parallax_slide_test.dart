import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/onboarding/presentation/widgets/parallax_slide.dart';

import '../../helpers/pump_app.dart';

void main() {
  const illustrationKey = ValueKey('ill');
  const textKey = ValueKey('txt');

  Future<void> pumpSlide(
    WidgetTester tester, {
    required double delta,
    bool reduceMotion = false,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpLapse(
      ParallaxSlide(
        delta: delta,
        illustration: const SizedBox(key: illustrationKey, width: 100),
        text: const SizedBox(key: textKey, width: 100, height: 40),
      ),
      reduceMotion: reduceMotion,
    );
  }

  double xOf(WidgetTester tester, Key key) =>
      tester.getTopLeft(find.byKey(key)).dx;

  testWidgets('moves illustration 0.4x and text 0.7x of the delta', (
    tester,
  ) async {
    await pumpSlide(tester, delta: 0);
    final illustrationBase = xOf(tester, illustrationKey);
    final textBase = xOf(tester, textKey);

    await pumpSlide(tester, delta: 0.5);
    expect(
      xOf(tester, illustrationKey) - illustrationBase,
      closeTo(0.5 * 390 * 0.4, 0.001),
    );
    expect(xOf(tester, textKey) - textBase, closeTo(0.5 * 390 * 0.7, 0.001));
  });

  testWidgets('offsets are zero under reduce motion', (tester) async {
    await pumpSlide(tester, delta: 0, reduceMotion: true);
    final illustrationBase = xOf(tester, illustrationKey);
    final textBase = xOf(tester, textKey);

    await pumpSlide(tester, delta: 0.5, reduceMotion: true);
    expect(xOf(tester, illustrationKey), illustrationBase);
    expect(xOf(tester, textKey), textBase);
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
