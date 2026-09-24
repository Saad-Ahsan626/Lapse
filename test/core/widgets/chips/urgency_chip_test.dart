import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/widgets/chips/urgency_chip.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('UrgencyChip', () {
    for (final (label, urgency) in const [
      ('Tomorrow', Urgency.urgent),
      ('In 3 days', Urgency.warning),
      ('Oct 24', Urgency.normal),
    ]) {
      testWidgets('shows its text for $urgency (never colour alone)', (
        tester,
      ) async {
        await tester.pumpLapse(UrgencyChip(label: label, urgency: urgency));
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(label), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(UrgencyChip)),
          matchesSemantics(label: label),
        );
      });
    }

    testWidgets('urgent chip pulses once per cycle', (tester) async {
      await tester.pumpLapse(
        const UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
      );
      await tester.pump(const Duration(milliseconds: 2900));
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump(const Duration(milliseconds: 150));
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(UrgencyChip),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final shadow = (box.decoration as BoxDecoration).boxShadow!.single;
      expect(shadow.spreadRadius, greaterThan(0));
      expect(shadow.spreadRadius, lessThanOrEqualTo(7));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('schedules no frames between pulses', (tester) async {
      await tester.pumpLapse(
        const UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
      );
      var framesDrawn = 0;
      for (var i = 0; i < 200; i++) {
        if (tester.binding.hasScheduledFrame) framesDrawn++;
        await tester.pump(const Duration(milliseconds: 1000 ~/ 60));
      }
      expect(framesDrawn, inInclusiveRange(1, 25));

      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('stops pulsing when urgency changes', (tester) async {
      await tester.pumpLapse(
        const UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
      );
      await tester.pumpLapse(
        const UrgencyChip(label: 'In 3 days', urgency: Urgency.warning),
      );
      await tester.pump(const Duration(seconds: 7));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('does not animate under reduce motion', (tester) async {
      await tester.pumpLapse(
        const UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
        reduceMotion: true,
      );
      await tester.pump(const Duration(seconds: 4));

      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
