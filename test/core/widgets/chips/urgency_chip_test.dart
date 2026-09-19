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

    testWidgets('urgent chip pulses and survives a full cycle', (tester) async {
      await tester.pumpLapse(
        const UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
      );
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('does not animate under reduce motion', (tester) async {
      await tester.pumpLapse(
        const UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
        reduceMotion: true,
      );
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
