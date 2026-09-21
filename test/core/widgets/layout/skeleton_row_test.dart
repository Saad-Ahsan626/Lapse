import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/layout/skeleton_row.dart';

import '../../../helpers/pump_app.dart';

Widget _row() => const SizedBox(width: 360, child: SkeletonRow());

void main() {
  group('SkeletonRow', () {
    testWidgets('renders a loading placeholder with a shimmer', (
      tester,
    ) async {
      await tester.pumpLapse(_row());
      await tester.pump(const Duration(milliseconds: 700));

      expect(tester.takeException(), isNull);
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
      expect(
        tester.getSize(find.byType(SkeletonRow)).height,
        greaterThanOrEqualTo(71),
      );
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('is static with reduce motion', (tester) async {
      await tester.pumpLapse(_row(), reduceMotion: true);

      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('renders in dark mode at text scale 2', (tester) async {
      await tester.pumpLapse(
        _row(),
        brightness: Brightness.dark,
        textScale: 2,
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
