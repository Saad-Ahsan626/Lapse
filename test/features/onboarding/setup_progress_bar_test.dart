import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/onboarding/presentation/widgets/setup_progress_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  Color colorOf(WidgetTester tester, int index) {
    final box = tester.widget<Container>(
      find.byKey(ValueKey('setup-progress-$index')),
    );
    return (box.decoration! as BoxDecoration).color!;
  }

  for (final brightness in Brightness.values) {
    testWidgets('fills two of three segments in ${brightness.name}', (
      tester,
    ) async {
      await tester.pumpLapse(
        const SetupProgressBar(),
        brightness: brightness,
      );
      final colors = brightness == Brightness.dark
          ? LapseColors.dark
          : LapseColors.light;

      expect(find.byType(Container), findsNWidgets(3));
      expect(colorOf(tester, 0), colors.primary);
      expect(colorOf(tester, 1), colors.primary);
      expect(colorOf(tester, 2), colors.ringTrack);
    });
  }

  testWidgets('segments share the width equally', (tester) async {
    await tester.pumpLapse(
      const SizedBox(width: 316, child: SetupProgressBar()),
    );

    final widths = [
      for (var i = 0; i < 3; i++)
        tester.getSize(find.byKey(ValueKey('setup-progress-$i'))).width,
    ];
    expect(widths.toSet(), hasLength(1));
    expect(widths.first, 100);
  });

  testWidgets('announces the step', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLapse(const SetupProgressBar(filled: 1));

    expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);
    handle.dispose();
  });
}
