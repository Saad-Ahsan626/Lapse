import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/motion/staggered_entrance.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('StaggeredEntrance', () {
    double opacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find.descendant(
            of: find.byType(StaggeredEntrance),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;

    double shift(WidgetTester tester) => tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(StaggeredEntrance),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .getTranslation()
        .y;

    testWidgets('ends fully visible, in place and tappable', (tester) async {
      var taps = 0;
      await tester.pumpLapse(
        StaggeredEntrance(
          index: 2,
          child: TextButton(onPressed: () => taps++, child: const Text('Row')),
        ),
      );

      expect(opacity(tester), 0);
      expect(shift(tester), 12);

      await tester.pumpAndSettle();
      expect(opacity(tester), 1);
      expect(shift(tester), 0);

      await tester.tap(find.text('Row'));
      expect(taps, 1);
    });

    testWidgets('waits index × 40ms before starting', (tester) async {
      await tester.pumpLapse(
        const StaggeredEntrance(index: 3, child: Text('Row')),
      );

      await tester.pump(const Duration(milliseconds: 110));
      expect(opacity(tester), 0);

      await tester.pump(const Duration(milliseconds: 60));
      expect(opacity(tester), greaterThan(0));
    });

    test('caps the delay at eight steps', () {
      expect(StaggeredEntrance.delayFor(0), Duration.zero);
      expect(
        StaggeredEntrance.delayFor(3),
        const Duration(milliseconds: 120),
      );
      expect(
        StaggeredEntrance.delayFor(20),
        const Duration(milliseconds: 320),
      );
    });

    testWidgets('shows the child immediately when animate is false', (
      tester,
    ) async {
      await tester.pumpLapse(
        const StaggeredEntrance(index: 2, animate: false, child: Text('Row')),
      );

      expect(opacity(tester), 1);
      expect(shift(tester), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('shows the child immediately with reduce motion', (
      tester,
    ) async {
      await tester.pumpLapse(
        const StaggeredEntrance(index: 5, child: Text('Row')),
        reduceMotion: true,
      );

      expect(opacity(tester), 1);
      expect(shift(tester), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
