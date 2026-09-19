import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/rings/countdown_ring.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('CountdownRing.clampProgress', () {
    test('never lets the ring disappear or overflow', () {
      expect(CountdownRing.clampProgress(0), 0.03);
      expect(CountdownRing.clampProgress(-1), 0.03);
      expect(CountdownRing.clampProgress(double.nan), 0.03);
      expect(CountdownRing.clampProgress(0.5), 0.5);
      expect(CountdownRing.clampProgress(1.7), 1);
    });
  });

  testWidgets('sweeps to its value and settles', (tester) async {
    await tester.pumpLapse(
      const CountdownRing(progress: 0.3, color: Colors.red, child: Text('3')),
    );

    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('does not animate under reduce motion', (tester) async {
    await tester.pumpLapse(
      const CountdownRing(progress: 0.3, color: Colors.red),
      reduceMotion: true,
    );
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
  });
}
