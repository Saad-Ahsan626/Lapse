import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/layout/swipe_action.dart';
import 'package:lapse/core/widgets/layout/swipe_actions.dart';
import 'package:lapse/core/widgets/layout/swipe_actions_group.dart';

import '../../../helpers/pump_app.dart';

class _Log {
  final List<String> events = [];
}

List<SwipeAction> _actions(_Log log, String row) => [
  SwipeAction(
    label: 'Cancelled',
    icon: Icons.check_rounded,
    color: Colors.green,
    foregroundColor: Colors.white,
    onTap: () => log.events.add('$row cancelled'),
  ),
  SwipeAction(
    label: 'Delete',
    icon: Icons.delete_outline_rounded,
    color: Colors.red,
    foregroundColor: Colors.white,
    onTap: () => log.events.add('$row delete'),
  ),
];

Widget _row(_Log log, String name) => SwipeActions(
  actions: _actions(log, name),
  child: Material(
    child: InkWell(
      onTap: () => log.events.add('$name tapped'),
      child: SizedBox(height: 70, child: Center(child: Text(name))),
    ),
  ),
);

Widget _list(_Log log) {
  final column = Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _row(log, 'Row A'),
      const SizedBox(height: 10),
      _row(log, 'Row B'),
    ],
  );
  return SizedBox(
    width: 360,
    child: SwipeActionsGroup(child: column),
  );
}

Future<void> _swipe(WidgetTester tester, String name, double dx) async {
  await tester.timedDrag(
    find.text(name),
    Offset(dx, 0),
    const Duration(milliseconds: 600),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SwipeActions', () {
    testWidgets('actions are hidden while closed', (tester) async {
      await tester.pumpLapse(_list(_Log()));

      expect(find.text('Delete'), findsNothing);
      expect(find.text('Cancelled'), findsNothing);
    });

    testWidgets('dragging left past 40% opens and shows the actions', (
      tester,
    ) async {
      final log = _Log();
      await tester.pumpLapse(_list(log));

      await _swipe(tester, 'Row A', -150);

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      final rowRight = tester.getTopRight(find.byType(SwipeActions).first).dx;
      expect(
        tester.getTopRight(find.text('Delete')).dx,
        lessThanOrEqualTo(rowRight),
      );
      expect(
        tester.getSize(find.byType(InkWell).at(1)),
        const Size(84, 70),
      );
      expect(log.events, isEmpty);
    });

    testWidgets('a short drag snaps back closed', (tester) async {
      await tester.pumpLapse(_list(_Log()));

      await _swipe(tester, 'Row A', -50);

      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('a fast fling left opens', (tester) async {
      await tester.pumpLapse(_list(_Log()));

      await tester.fling(find.text('Row A'), const Offset(-60, 0), 1500);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('dragging right closes an open row', (tester) async {
      await tester.pumpLapse(_list(_Log()));
      await _swipe(tester, 'Row A', -150);

      await _swipe(tester, 'Row A', 150);

      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('tapping an action calls it and closes the row', (
      tester,
    ) async {
      final log = _Log();
      await tester.pumpLapse(_list(log));
      await _swipe(tester, 'Row A', -150);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(log.events, ['Row A delete']);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('tapping the open child closes it without tapping it', (
      tester,
    ) async {
      final log = _Log();
      await tester.pumpLapse(_list(log));
      await _swipe(tester, 'Row A', -150);

      await tester.tap(find.text('Row A'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsNothing);
      expect(log.events, isEmpty);

      await tester.tap(find.text('Row A'));
      expect(log.events, ['Row A tapped']);
    });

    testWidgets('opening a row in a group closes the other one', (
      tester,
    ) async {
      await tester.pumpLapse(_list(_Log()));
      await _swipe(tester, 'Row A', -150);
      expect(find.text('Delete'), findsOneWidget);

      await _swipe(tester, 'Row B', -150);

      expect(find.text('Delete'), findsOneWidget);
      final rowB = tester.getRect(find.byType(SwipeActions).at(1));
      expect(rowB.contains(tester.getCenter(find.text('Delete'))), isTrue);
    });

    testWidgets('snaps instantly with reduce motion', (tester) async {
      await tester.pumpLapse(_list(_Log()), reduceMotion: true);

      await tester.timedDrag(
        find.text('Row A'),
        const Offset(-150, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pump();

      expect(find.text('Delete'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('closes when an ancestor scrollable scrolls', (tester) async {
      await tester.pumpLapse(
        SizedBox(
          width: 360,
          height: 300,
          child: ListView(
            children: [
              _list(_Log()),
              const SizedBox(height: 800),
            ],
          ),
        ),
      );
      await _swipe(tester, 'Row A', -150);
      expect(find.text('Delete'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('exposes the actions as custom semantics actions', (
      tester,
    ) async {
      final log = _Log();
      await tester.pumpLapse(_list(log));

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(SwipeActions).first,
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Semantics &&
                    w.properties.customSemanticsActions != null,
              ),
            )
            .first,
      );
      final actions = semantics.properties.customSemanticsActions!;
      expect(actions.keys.map((a) => a.label), ['Cancelled', 'Delete']);

      final node = tester.getSemantics(find.text('Row A'));
      final data = node.getSemanticsData();
      expect(data.customSemanticsActionIds, hasLength(2));

      final cancelled = actions.keys.first;
      node.owner!.performAction(
        node.id,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(cancelled),
      );
      await tester.pumpAndSettle();

      expect(log.events, ['Row A cancelled']);
    });
  });
}
