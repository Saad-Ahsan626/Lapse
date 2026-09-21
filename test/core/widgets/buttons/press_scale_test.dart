import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/widgets/buttons/press_scale.dart';

import '../../../helpers/pump_app.dart';

void main() {
  AnimatedScale scaleOf(WidgetTester tester) =>
      tester.widget<AnimatedScale>(find.byType(AnimatedScale));

  double shownScale(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byType(AnimatedScale),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;

  const box = PressScale(
    child: SizedBox.square(
      dimension: 80,
      child: ColoredBox(color: Colors.red),
    ),
  );

  testWidgets('scales to 0.97 over 120ms and back over 180ms', (
    tester,
  ) async {
    await tester.pumpLapse(box);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressScale)),
    );
    await tester.pump();
    expect(scaleOf(tester).scale, 0.97);
    expect(scaleOf(tester).duration, const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 60));
    expect(shownScale(tester), inExclusiveRange(0.97, 1));
    await tester.pump(const Duration(milliseconds: 60));
    expect(shownScale(tester), closeTo(0.97, 1e-9));

    await gesture.up();
    await tester.pump();
    expect(scaleOf(tester).scale, 1);
    expect(scaleOf(tester).duration, const Duration(milliseconds: 180));
    await tester.pump(const Duration(milliseconds: 90));
    expect(shownScale(tester), inExclusiveRange(0.97, 1));
    await tester.pump(const Duration(milliseconds: 90));
    expect(shownScale(tester), closeTo(1, 1e-9));
  });

  testWidgets('does not scale with reduce motion', (tester) async {
    await tester.pumpLapse(box, reduceMotion: true);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressScale)),
    );
    await tester.pump();
    expect(scaleOf(tester).scale, 1);
    await gesture.up();
  });
}
