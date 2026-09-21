import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/widgets/buttons/lapse_fab.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('LapseFab', () {
    AnimatedRotation rotation(WidgetTester tester) =>
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation));

    testWidgets('is a 56px circle that calls onPressed', (tester) async {
      var taps = 0;
      await tester.pumpLapse(LapseFab(onPressed: () => taps++));

      expect(tester.getSize(find.byType(InkWell)), const Size(56, 56));
      await tester.tap(find.byType(LapseFab));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(LapseFab)),
        matchesSemantics(
          label: 'Add subscription',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('icon is not rotated when closed', (tester) async {
      await tester.pumpLapse(LapseFab(onPressed: () {}));

      expect(rotation(tester).turns, 0);
      expect(rotation(tester).duration, const Duration(milliseconds: 200));
      expect(rotation(tester).curve, Curves.easeInCubic);
    });

    testWidgets('rotates 45 degrees on the sheet spring when open', (
      tester,
    ) async {
      await tester.pumpLapse(LapseFab(onPressed: () {}, open: true));

      expect(rotation(tester).turns, 0.125);
      expect(rotation(tester).duration, const Duration(milliseconds: 360));
      expect(rotation(tester).curve, Motion.springCurve);
    });

    testWidgets('rotates instantly with reduce motion', (tester) async {
      await tester.pumpLapse(
        LapseFab(onPressed: () {}, open: true),
        reduceMotion: true,
      );

      expect(rotation(tester).duration, Duration.zero);
    });
  });
}
