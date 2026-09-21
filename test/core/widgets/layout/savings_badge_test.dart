import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/theme/tokens/lapse_colors.dart';
import 'package:lapse/core/widgets/brand/logo_mark.dart';
import 'package:lapse/core/widgets/layout/savings_badge.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('SavingsBadge', () {
    testWidgets('is a mint circle with the mark in savings colour', (
      tester,
    ) async {
      await tester.pumpLapse(const SavingsBadge());

      expect(tester.getSize(find.byType(SavingsBadge)), const Size(92, 92));
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(SavingsBadge),
          matching: find.byType(Container),
        ),
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, LapseColors.light.savingsTint);
      expect(decoration.shape, BoxShape.circle);
      final mark = tester.widget<LogoMark>(find.byType(LogoMark));
      expect(mark.color, LapseColors.light.savings);
      expect(mark.size, closeTo(92 * 0.56, 0.001));
    });

    testWidgets('scales with size', (tester) async {
      await tester.pumpLapse(const SavingsBadge(size: 60));

      expect(tester.getSize(find.byType(SavingsBadge)), const Size(60, 60));
    });

    testWidgets('reads as a single Cancelled image', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpLapse(const SavingsBadge());

      expect(find.bySemanticsLabel('Cancelled'), findsOneWidget);
      expect(find.bySemanticsLabel('Lapse logo'), findsNothing);
      expect(
        tester.getSemantics(find.byType(SavingsBadge)),
        matchesSemantics(label: 'Cancelled', isImage: true),
      );
      handle.dispose();
    });
  });
}
