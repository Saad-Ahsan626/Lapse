import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/onboarding/presentation/widgets/worm_indicator.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<List<double>> widthsAt(WidgetTester tester, double page) async {
    await tester.pumpLapse(WormIndicator(page: page, count: 3));
    return [
      for (var i = 0; i < 3; i++)
        tester.getSize(find.byKey(ValueKey('worm-dot-$i'))).width,
    ];
  }

  testWidgets('active dot is a 24px pill, others 7px dots', (tester) async {
    expect(await widthsAt(tester, 0), [24, 7, 7]);
    expect(await widthsAt(tester, 1), [7, 24, 7]);
    expect(await widthsAt(tester, 2), [7, 7, 24]);
  });

  testWidgets('stretch follows the fractional page', (tester) async {
    expect(await widthsAt(tester, 0.5), [15.5, 15.5, 7]);
    expect(
      tester.getSize(find.byKey(const ValueKey('worm-dot-0'))).height,
      7,
    );
  });

  testWidgets('announces the current page', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLapse(const WormIndicator(page: 1, count: 3));
    expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);
    handle.dispose();
  });
}
