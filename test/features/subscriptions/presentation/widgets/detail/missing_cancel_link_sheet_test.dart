import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/detail_menu.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/missing_cancel_link_sheet.dart';

import '../../../../../helpers/pump_app.dart';
import 'detail_test_support.dart';

void main() {
  Future<List<Object?>> pumpOpener(
    WidgetTester tester,
    Future<Object?> Function(BuildContext context) open, {
    double textScale = 1,
  }) async {
    final results = <Object?>[];
    await tester.pumpLapse(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(await open(context)),
          child: const Text('open'),
        ),
      ),
      textScale: textScale,
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    return results;
  }

  testWidgets('missing link sheet returns add link', (tester) async {
    final results = await pumpOpener(tester, showMissingCancelLinkSheet);

    expect(find.text('No cancel link yet'), findsOneWidget);
    await tester.tap(find.text('Add a cancel link'));
    await settle(tester);

    expect(results, [MissingCancelLinkChoice.addLink]);
  });

  testWidgets('missing link sheet returns search', (tester) async {
    final results = await pumpOpener(tester, showMissingCancelLinkSheet);

    await tester.tap(find.text('Search how to cancel'));
    await settle(tester);

    expect(results, [MissingCancelLinkChoice.search]);
  });

  testWidgets('missing link sheet closes with nothing', (tester) async {
    final results = await pumpOpener(
      tester,
      showMissingCancelLinkSheet,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('Close'));
    await settle(tester);

    expect(results, [null]);
  });

  testWidgets('menu offers restore only when cancelled', (tester) async {
    final results = await pumpOpener(
      tester,
      (context) => showDetailMenu(context, name: 'Netflix', isCancelled: true),
    );

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await settle(tester);

    expect(results, [DetailMenuAction.restore]);
  });

  testWidgets('menu for an active subscription only deletes', (tester) async {
    final results = await pumpOpener(
      tester,
      (context) => showDetailMenu(context, name: 'Netflix', isCancelled: false),
    );

    expect(find.text('Restore'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Delete'));
    await settle(tester);

    expect(results, [DetailMenuAction.delete]);
  });
}
