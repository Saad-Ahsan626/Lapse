import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/widgets/widgets.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Finder boundaryIn(Type type) => find.descendant(
    of: find.byType(type),
    matching: find.byType(RepaintBoundary),
  );

  group('continuous animations sit behind a RepaintBoundary', () {
    testWidgets('urgent chip pulse', (tester) async {
      await tester.pumpLapse(
        const UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
      );
      expect(boundaryIn(UrgencyChip), findsWidgets);
    });

    testWidgets('skeleton shimmer', (tester) async {
      await tester.pumpLapse(const SkeletonRow());
      expect(boundaryIn(SkeletonRow), findsWidgets);
    });

    testWidgets('confetti', (tester) async {
      await tester.pumpLapse(const ConfettiBurst(play: true));
      expect(boundaryIn(ConfettiBurst), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('count-up', (tester) async {
      await tester.pumpLapse(CountUpText(value: 1200, format: (v) => '$v'));
      expect(boundaryIn(CountUpText), findsWidgets);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('countdown ring', (tester) async {
      await tester.pumpLapse(
        const CountdownRing(progress: 0.4, color: Colors.red),
      );
      expect(boundaryIn(CountdownRing), findsWidgets);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('urgent pulse ring', () {
    double? spread(WidgetTester tester) {
      final boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(UrgencyChip),
          matching: find.byType(DecoratedBox),
        ),
      );
      for (final box in boxes) {
        final decoration = box.decoration;
        final shadows = decoration is BoxDecoration
            ? decoration.boxShadow
            : null;
        if (shadows != null &&
            shadows.isNotEmpty &&
            shadows.first.color.a > 0) {
          return shadows.first.spreadRadius;
        }
      }
      return null;
    }

    testWidgets('grows outward to 7px over 300ms once every 3s', (
      tester,
    ) async {
      await tester.pumpLapse(
        const UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
      );

      await tester.pump(const Duration(milliseconds: 2900));
      expect(spread(tester), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));
      expect(spread(tester), inExclusiveRange(0, 7));
      await tester.pump(const Duration(milliseconds: 130));
      expect(spread(tester), closeTo(7, 0.5));
      await tester.pump(const Duration(milliseconds: 100));
      expect(spread(tester), isNull);
      await tester.pump(const Duration(milliseconds: 2620));
      await tester.pump(const Duration(milliseconds: 150));
      expect(spread(tester), inExclusiveRange(0, 7));
    });

    testWidgets('never pulses for non-urgent chips or reduce motion', (
      tester,
    ) async {
      await tester.pumpLapse(
        const UrgencyChip(label: 'In 5 days', urgency: Urgency.warning),
      );
      await tester.pump(const Duration(milliseconds: 3200));
      expect(spread(tester), isNull);

      await tester.pumpLapse(
        const UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
        reduceMotion: true,
      );
      await tester.pump(const Duration(milliseconds: 3200));
      expect(spread(tester), isNull);
    });
  });
}
