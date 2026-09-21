import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/widgets/layout/lapse_sheet_route.dart';

import 'catalog_picker_harness.dart';

void main() {
  ModalBottomSheetRoute<dynamic> sheetRoute(WidgetTester tester) =>
      ModalRoute.of(tester.element(find.text('Add subscription')))!
          as ModalBottomSheetRoute<dynamic>;

  double titleTop(WidgetTester tester) =>
      tester.getTopLeft(find.text('Add subscription')).dy;

  testWidgets('the sheet springs up over 360ms with damping 0.72', (
    tester,
  ) async {
    await pumpPickerApp(tester);
    await tester.tap(find.text('Open picker'));
    await tester.pump();

    final style = sheetRoute(tester).sheetAnimationStyle!;
    expect(style.duration, const Duration(milliseconds: 360));
    expect(
      (sheetRoute(tester) as LapseSheetRoute<dynamic>).entranceCurve,
      Motion.springCurve,
    );
    expect(Motion.springCurve.dampingRatio, 0.72);

    await tester.pump(const Duration(milliseconds: 170));
    final overshoot = titleTop(tester);
    await tester.pump(const Duration(milliseconds: 200));
    final rest = titleTop(tester);
    await settle(tester);

    expect(titleTop(tester), rest);
    expect(overshoot, lessThan(rest));
  });

  testWidgets('the sheet opens instantly with reduce motion', (tester) async {
    await pumpPickerApp(
      tester,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: const PickerLauncher(),
        ),
      ),
    );
    await tester.tap(find.text('Open picker'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    final style = sheetRoute(tester).sheetAnimationStyle!;
    expect(style.duration, const Duration(milliseconds: 1));
    expect(
      (sheetRoute(tester) as LapseSheetRoute<dynamic>).entranceCurve,
      isNull,
    );
    final top = titleTop(tester);
    await settle(tester);
    expect(titleTop(tester), top);
  });
}
