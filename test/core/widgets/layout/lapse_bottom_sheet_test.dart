import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/layout/lapse_bottom_sheet.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('showLapseSheet', () {
    Widget opener({String? title, bool showClose = true}) => Builder(
      builder: (context) => TextButton(
        onPressed: () => showLapseSheet<void>(
          context: context,
          title: title,
          showClose: showClose,
          builder: (_) => const Text('Body'),
        ),
        child: const Text('Open'),
      ),
    );

    testWidgets('shows title and close button, and closes', (tester) async {
      await tester.pumpLapse(opener(title: 'Add subscription'));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add subscription'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.bySemanticsLabel('Close'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsNothing);
    });

    testWidgets('has no header without a title', (tester) async {
      await tester.pumpLapse(opener());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('hides the close button when showClose is false', (
      tester,
    ) async {
      await tester.pumpLapse(opener(title: 'Title', showClose: false));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Title'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('opens almost instantly with reduce motion', (tester) async {
      await tester.pumpLapse(opener(title: 'Title'), reduceMotion: true);

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5));

      expect(find.text('Body'), findsOneWidget);
      final early = tester.getRect(find.text('Body'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Body')), early);
    });
  });
}
